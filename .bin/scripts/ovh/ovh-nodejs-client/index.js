require("dotenv").config();
const { program: cli } = require("commander");
const { getClient } = require("./api");
const {
  configureFirewall,
  activateMitigation,
  closeService,
  getAllIp,
} = require("./firewall");

function handleError(e) {
  console.error(e.constructor.name === "EnvVarError" ? e.message : e);
  process.exit(1); // eslint-disable-line no-process-exit
}
process.on("unhandledRejection", handleError);
process.on("uncaughtException", handleError);

cli
  .command("ping")
  .description("Permet de verifier que la clé est valide")
  .option("--key <key>", "La consumer key")
  .action(async ({ key }) => {
    let client = await getClient(key);

    await client.requestPromised("GET", `/auth/time`);
  });

cli
  .command("createFirewall <ip> <product>")
  .description("Permet de créer/configurer le firewall et d'activer la mitigation")
  .option("--key <key>", "La consumer key")
  .action(async (ip, product, { key }) => {
    let client = await getClient(key);

    const ips = await getAllIp(client, ip);

    for (const ipV4 of ips) {
      await configureFirewall(client, ipV4, product);
      await activateMitigation(client, ipV4);
      console.log(`Firewall and mitigation activated for VPS ${ipV4}`);
    }
  });

cli
  .command("closeService <ip>")
  .description("Permet de créer/configurer le firewall pour fermer le service sur les ports 80 et 443")
  .option("--key <key>", "La consumer key")
  .action(async (ip, { key }) => {
    let client = await getClient(key);

    const ips = await getAllIp(client, ip);

    for (const ipV4 of ips) {
      await closeService(client, ipV4);
      console.log(`Service closed on port for VPS ${ipV4}.`);
    }
  });

cli.parse(process.argv);
