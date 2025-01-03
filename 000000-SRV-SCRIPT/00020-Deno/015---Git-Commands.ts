#!/opt/SERVER/400-PROG-TOOLS/404-SCRIPTS/deno

import { Octokit } from "https://esm.sh/@octokit/core";
import { Gitlab } from "https://esm.sh/@gitbeaker/rest";
import { parse } from "https://deno.land/std/flags/mod.ts";
import { readLines } from "https://deno.land/std/io/mod.ts";
import { join } from "https://deno.land/std/path/mod.ts";
import { exists } from "https://deno.land/std/fs/mod.ts";

async function isRepoAlreadyCloned(repoPath: string): Promise<boolean>;
async function isRepoAlreadyCloned(repoPath: string): Promise<boolean> {
  return await exists(repoPath);
}
// Configuration
const GITHUB_TOKEN = Deno.env.get("GITHUB_TOKEN");
const GITLAB_TOKEN = Deno.env.get("GITLAB_TOKEN");

if (!GITHUB_TOKEN || !GITLAB_TOKEN) {
  console.error("Veuillez définir GITHUB_TOKEN et GITLAB_TOKEN dans les variables d'environnement.");
  Deno.exit(1);
}

const octokit = new Octokit({ auth: GITHUB_TOKEN });
const gitlab = new Gitlab({ token: GITLAB_TOKEN });

async function readEnvFile(filePath: string): Promise<Map<string, string>> {
  const envMap = new Map<string, string>();
  const fileReader = await Deno.open(filePath);

  for await (const line of readLines(fileReader)) {
    const [key, value] = line.split('=');
    if (key && value) {
      envMap.set(key.trim(), value.trim());
    }
  }

  fileReader.close();
  return envMap;
}

function getDestinationFolder(repoNumber: number): string {
  if (repoNumber >= 200 && repoNumber < 300) return "./200-SERVICES-BASE";
  if (repoNumber >= 300 && repoNumber < 400) return "./300-SERVICES-SPEC";
  if (repoNumber >= 400 && repoNumber < 500) return "./400-PROG-TOOLS";
  if (repoNumber >= 500 && repoNumber < 600) return "./500-DATABASE";
  if (repoNumber >= 600 && repoNumber < 700) return "./600-IA-LOCAL";
  return ".";
}

async function cloneRepo(repoUrl: string, destPath: string) {
  const command = new Deno.Command("git", {
    args: ["clone", repoUrl, destPath],
    stdout: "piped",
    stderr: "piped",
  });
  const { stdout, stderr } = await command.output();

  if (stdout) {
    console.log(new TextDecoder().decode(stdout));
  }
  if (stderr) {
    console.error(new TextDecoder().decode(stderr));
  }
}

async function githubOperations(owner: string, repo: string) {
  console.log("GitHub Operations:");
  
  // Status
  const status = await octokit.request("GET /repos/{owner}/{repo}/commits/main", {
    owner,
    repo,
  });
  console.log("Status:", status.data.sha);

  // Pull
  const pull = await octokit.request("GET /repos/{owner}/{repo}/git/refs/heads/main", {
    owner,
    repo,
  });
  console.log("Pull:", pull.data.object.sha);
}

async function gitlabOperations(owner: string, repo: string) {
  console.log("\nGitLab Operations:");
  
  // Status
  const status = await gitlab.Repositories.showBranch(owner + "/" + repo, "main");
  console.log("Status:", status.commit.id);

  // Pull
  const pull = await gitlab.Repositories.showBranch(owner + "/" + repo, "main");
  console.log("Pull:", pull.commit.id);
}

async function main() {
  const args = parse(Deno.args);
  const command = args._[0];
  const repoNumber = args._[1];

  if (!command || !repoNumber || (command !== "githubclone" && command !== "gitlabclone")) {
    console.error("Usage: deno task githubclone <repo_number> OR deno task gitlabclone <repo_number>");
    Deno.exit(1);
  }

  const envFile = command === "githubclone" 
    ? "/opt/SERVER/400-PROG-TOOLS/402-ENV-BASE/GITHUB.ENV"
    : "/opt/SERVER/400-PROG-TOOLS/402-ENV-BASE/GITLAB.ENV";

  const envMap = await readEnvFile(envFile);
  const repoUrl = envMap.get(repoNumber as string);

  if (!repoUrl) {
    console.error(`No repository found for number ${repoNumber}`);
    Deno.exit(1);
  }

  const repoName = repoUrl.split('/').pop()?.replace('.git', '');
  const owner = "devreos";

  const destinationFolder = getDestinationFolder(Number(repoNumber));
  const fullDestPath = join(destinationFolder, repoName!);

  try {
    if (await isRepoAlreadyCloned(fullDestPath)) {
      console.log(`Repository already exists at ${fullDestPath}. Updating...`);
      await updateExistingRepo(fullDestPath);
    } else {
      if (command === "githubclone") {
        await githubOperations(owner, repoName!);
      } else {
        await gitlabOperations(owner, repoName!);
      }
      
      // Clone the repository
      await cloneRepo(repoUrl, fullDestPath);
    }
  } catch (error) {
    console.error("Une erreur est survenue:", error);
  }
}

if (import.meta.main) {
  main();
}