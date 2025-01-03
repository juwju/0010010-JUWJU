import { config as loadEnv } from "dotenv";
import { join } from "std/path/mod.ts";
import { exists } from "std/fs/mod.ts";

// Types
type ServiceInfo = {
  AppID: string;
  ServiceID: string;
  MicroServiceID: string;
  Version: string;
  AppNumber: string;
  ServiceNumber: string;
  MicroServiceNumber: string;
  MicroServiceGitNumber: string;
};

type DockerCommand = 'up' | 'down' | 'restart';

// Ajout d'un type pour les options
type CommandOptions = {
  detached: boolean;
  build: boolean;
};

async function convertHostToNamedVolume(
  hostPath: string, 
  volumeName: string,
  stackName: string
): Promise<boolean> {
  try {
    // Créer un conteneur temporaire avec le volume nommé
    const tempContainer = new Deno.Command("docker", {
      args: [
        "run",
        "-d",
        "--name", "temp-volume-container",
        "-v", `${volumeName}:/dest`,
        "alpine",
        "tail", "-f", "/dev/null"
      ]
    });
    await tempContainer.output();

    // Copier les données du dossier hôte vers le conteneur
    const copyData = new Deno.Command("docker", {
      args: [
        "cp",
        `${hostPath}/.`,
        "temp-volume-container:/dest/"
      ]
    });
    await copyData.output();

    // Ajuster les permissions
    const chown = new Deno.Command("docker", {
      args: [
        "exec",
        "temp-volume-container",
        "chown",
        "-R",
        "1000:1000",
        "/dest"
      ]
    });
    await chown.output();

    // Nettoyer le conteneur temporaire
    const cleanup = new Deno.Command("docker", {
      args: [
        "rm",
        "-f",
        "temp-volume-container"
      ]
    });
    await cleanup.output();

    return true;
  } catch (error) {
    console.error(`Erreur lors de la conversion: ${error}`);
    return false;
  }
}

async function validateAndCreateNetworksFromEnv(
  actualServerId: string,
  appId: string,
  serviceId: string,
  networkName: string
) {
  try {
    // Vérifier si Swarm est initialisé
    const checkSwarmCmd = new Deno.Command("docker", {
      args: ["info", "--format", "{{.Swarm.LocalNodeState}}"],
      stdout: "piped",
      stderr: "piped",
    });
    const swarmStatus = await checkSwarmCmd.spawn().output();
    const swarmState = new TextDecoder().decode(swarmStatus.stdout).trim();

    if (swarmState !== "active") {
      console.log("⚠ Docker Swarm n'est pas initialisé. Initialisation...");
      const initCmd = new Deno.Command("docker", {
        args: ["swarm", "init"],
        stdout: "inherit",
        stderr: "inherit",
      });
      const { code: initCode } = await initCmd.spawn().status;
      
      if (initCode !== 0) {
        throw new Error("Échec de l'initialisation de Docker Swarm");
      }
      console.log("✓ Docker Swarm initialisé avec succès");
    }

    // Construire le sous-réseau
    const subnet = `2${actualServerId}.${appId}.${serviceId}.0/24`;

    // Vérifier si le réseau existe
    const checkNetworkCmd = new Deno.Command("docker", {
      args: ["network", "inspect", networkName],
      stdout: "null",
      stderr: "null",
    });
    const { code } = await checkNetworkCmd.spawn().status;

    if (code === 0) {
      console.log(`✓ Réseau Docker "${networkName}" existe déjà.`);
    } else {
      console.log(`⚠ Réseau Docker "${networkName}" introuvable. Création...`);
      const createCmd = new Deno.Command("docker", {
        args: [
          "network",
          "create",
          "--driver", "overlay",
          "--attachable",
          "--subnet", subnet,
          "--opt", "encrypted=true",
          "--opt", "com.docker.network.driver.mtu=1420",
          networkName
        ],
        stdout: "inherit",
        stderr: "inherit",
      });
      const { code: createCode } = await createCmd.spawn().status;

      if (createCode === 0) {
        console.log(`✓ Réseau Docker "${networkName}" créé avec succès.`);
      } else {
        throw new Error(`Échec de la création du réseau "${networkName}".`);
      }
    }
  } catch (error) {
    console.error(`Erreur lors de la validation/création du réseau "${networkName}": ${error.message}`);
    throw error;
  }
}



// Fonction pour parser les informations du service
function parseServiceInfo(service: string): ServiceInfo {
  if (service.length !== 5) {
    throw new Error('Le format du service doit être de 5 caractères (ex: 01310)');
  }

  return {
    AppID: service[0],
    ServiceID: service[1],
    MicroServiceID: service[2] + service[3],
    Version: service[4],
    AppNumber: service[0] + '0000',
    ServiceNumber: service[0] + service[1] + '000',
    MicroServiceNumber: service[1] + service[2] + service[3] + service[4],
    MicroServiceGitNumber: '0'+ service[2] + service[3] + service[4]
  };
}

// Fonction pour vérifier si un fichier existe
async function validateFile(path: string): Promise<void> {
  if (!await exists(path)) {
    throw new Error(`Le fichier ${path} n'existe pas`);
  }
}


function interpolateEnvVars(envVars: Record<string, string>): Record<string, string> {
  const interpolated: Record<string, string> = {};
  const regex = /\${(\w+)}|\$(\w+)/g;

  for (const [key, value] of Object.entries(envVars)) {
    interpolated[key] = value.replace(regex, (_, p1, p2) => {
      const varName = p1 || p2;
      return envVars[varName] || '';
    });
  }

  return interpolated;
}

async function loadEnvFiles(envFiles: string[], detached: boolean = false) {
  const envVars: Record<string, string> = {};
  
  for (const file of envFiles) {
      if (await exists(file)) {
          const fileEnv = loadEnv({ path: file, export: false });
          // Fusionner les nouvelles variables avec les existantes
          Object.assign(envVars, fileEnv);
          if (!detached) console.log(`✓ Fichier chargé: ${file}`);
      }
  }
  
  if (Object.keys(envVars).length === 0) {
      throw new Error("Aucune variable d'environnement n'a été chargée");
  }
  
  // Appliquer les variables à l'environnement une seule fois
  for (const [key, value] of Object.entries(envVars)) {
      Deno.env.set(key, value);
  }
  
  return interpolateEnvVars(envVars);
}



function validateRequiredEnvVars(envVars: Record<string, string>, requiredKeys: string[]): void {
  for (const key of requiredKeys) {
    if (!envVars[key]) {
      throw new Error(`Variable d'environnement manquante: ${key}`);
    }
  }
}

// Fonction pour exécuter Docker Compose
async function runDockerCompose(
  command: DockerCommand, 
  serviceInfo: ServiceInfo, 
  envVars: Record<string, string>, 
  baseDir: string, 
  cmdOptions: CommandOptions
) {
  const dockerComposeFile = join(baseDir, `${serviceInfo.MicroServiceGitNumber}-docker-compose.yml`);
  await validateFile(dockerComposeFile);

  const dockerComposeCommand = [
    'docker',
    'compose',
    '-f',
    dockerComposeFile,
    '-p',
    envVars.PROJECT_NAME,
    command
  ];

  if (cmdOptions.build) {
    dockerComposeCommand.push('--build');
  }

  if (!cmdOptions.detached) {
    console.log(`\n${envVars.SERVICE_NAME} : 🚀 Démarrage du Micro-Service ${envVars.MICROSERVICE_NAME} ...`);
    console.log('Exécution de la commande:', dockerComposeCommand.join(' '));
  }

  try {
    const cmd = new Deno.Command(dockerComposeCommand[0], {
      args: dockerComposeCommand.slice(1),
      env: envVars,
      stdout: "inherit",
      stderr: "inherit"
    });

    const { code } = await cmd.spawn().status;

    if (code !== 0) {
      console.log(`\n${envVars.SERVICE_NAME} : ❌ Erreur lors du démarrage du Micro-Service ${envVars.MICROSERVICE_NAME}`);
      throw new Error(`La commande docker-compose a échoué avec le code ${code}`);
    }

    if (!cmdOptions.detached) {
      console.log(`\n${envVars.SERVICE_NAME} : ✅ Micro-Service ${envVars.MICROSERVICE_NAME} démarré avec succès\n`);
    }
  } catch (error) {
    console.error(`\n${envVars.SERVICE_NAME} : ❌ Erreur:`, error.message);
    throw error;
  }
}


// Nouvelle fonction pour trouver le répertoire du service
async function findDirectory(serviceDir: string, servicePrefix: string): Promise<string | null> {
  try {
    for await (const entry of Deno.readDir(serviceDir)) {
      if (entry.isDirectory && entry.name.startsWith(`${servicePrefix}-`)) {
        return entry.name;
      }
    }
  } catch (error) {
    console.error(`Erreur lors de la recherche du répertoire: ${error}`);
  }
  return null;
}

// ------------------------------------------------------------------------------------------------
// MAIN
// ------------------------------------------------------------------------------------------------

async function main() {
  try {
    const args = Deno.args;
    let command: DockerCommand = 'up';
    let serviceArg = '';
    const options: CommandOptions = {
      detached: false,
      build: false
    };

    // Parse les arguments
    for (let i = 0; i < args.length; i++) {
      const arg = args[i];
      if (arg === '--build') {
        options.build = true;
      } else if (arg === '-d') {
        options.detached = true;
      } else if (arg === 'up' || arg === 'down' || arg === 'restart') {
        command = arg;
      } else {
        serviceArg = arg;
      }
    }

    // Validation du service
    if (!serviceArg) {
      throw new Error('Le numéro de service est requis');
    }

    const serviceInfo = parseServiceInfo(serviceArg);
    if (!options.detached) console.log('Service info:', serviceInfo);

    // Trouver le répertoire du service
    const BaseDir = Deno.cwd();
    const ServiceDir = await findDirectory(BaseDir, `0${serviceInfo.ServiceNumber}`);
    if (!ServiceDir) {
      throw new Error(`Aucun répertoire trouvé pour le service ${serviceInfo.ServiceNumber}`);
    }
    else
    {
      if (!options.detached) console.log(`Service Directory: ${ServiceDir}`);
    }

    // Trouver le répertoire du MicroService
    const MicroServiceDir = await findDirectory(ServiceDir, `${serviceInfo.AppID}${serviceInfo.MicroServiceNumber}`);
    if (!MicroServiceDir) {
      throw new Error(`Aucun répertoire trouvé pour le micro-service ${serviceInfo.AppID}${serviceInfo.MicroServiceNumber}`);
    }
    else
    {
      if (!options.detached) console.log(`MicroService Directory: ${MicroServiceDir}`);
    }

    const EnvDir = join(BaseDir,ServiceDir,MicroServiceDir);

    // Charger les fichiers .env dans l'ordre hiérarchique
    const envFiles = [
      join('/opt','000000-srv-Server.env'),
      join(BaseDir, `000000-App.env`),
      join(BaseDir, ServiceDir, `${serviceInfo.AppNumber}-Service.env`),
      join(EnvDir, `${serviceInfo.MicroServiceGitNumber}-MicroService.env`),
    ];

    const envVars = await loadEnvFiles(envFiles, options.detached);
    validateRequiredEnvVars(envVars, ['ACTUAL_SERVER_ID', 'NETWORK_NAME', 'PROJECT_NAME']);
    // Affichage détaillé des variables d'environnement
    if (!options.detached) {
      console.log('\nVariables d\'environnement chargées:');
      console.log('------------------------------------');
      Object.entries(envVars).forEach(([key, value]) => {
        console.log(`${key}: ${value}`);
      });
      console.log('------------------------------------\n');
    }
    /*await validateAndCreateNetworksFromEnv(
      envVars.ACTUAL_SERVER_ID,
      serviceInfo.AppID,
      serviceInfo.ServiceID,
      envVars.NETWORK_NAME
    );*/
    await runDockerCompose(command, serviceInfo, envVars, EnvDir, options);
  } catch (error) {
    console.error('Erreur:', error.message);
    Deno.exit(1);
  }
}

if (import.meta.main) {
  main();
}