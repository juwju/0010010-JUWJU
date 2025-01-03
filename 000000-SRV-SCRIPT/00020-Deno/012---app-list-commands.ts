// Mettez à jour les importations std vers la dernière version
import { Table } from "https://deno.land/x/cliffy@v1.0.0-rc.3/table/mod.ts";
import * as colors from "https://deno.land/std@0.200.0/fmt/colors.ts";

// Si vous importez des fichiers JSON, utilisez la syntaxe 'with' au lieu de 'assert'
const data = {
  "commands": [
    {
      "name": "upprod",
      "variable": "101",
      "description": "Lancement du Frontend en prod",
      "environnement": "Production"
    },
    {
      "name": "downprod",
      "variable": "101",
      "description": "Arrêt du Frontend en prod",
      "environnement": "Production"
    },
    {
      "name": "updev",
      "variable": "101",
      "description": "Lancement du Frontend en développement",
      "environnement": "Développement"
    },
    {
      "name": "downprod",
      "variable": "101",
      "description": "Arrêt du Frontend en développement",
      "environnement": "Développement"
    },
  ],
  "services": [
    "101",
    "102"
  ],
  "version": "1.0.0"
};

const table = new Table()
  .header(["Commande", "# Service", "Description", "Catégorie"])
  .body(data.commands.map(cmd => [
    colors.green(cmd.name),
    colors.blue(cmd.variable),
    cmd.description,
    cmd.environnement
  ]))
  .border(true);
console.log()
console.log(`Version : ${data.version}`);
console.log(table.toString());
console.log()

// Affichage des catégories disponibles
console.log("Services disponibles :");
data.services.forEach(service => {
  console.log(colors.blue(` ${service}`));
});

