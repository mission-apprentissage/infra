import env from "env-var";
import open from "open";
import ovh from "@ovhcloud/node-ovh";

function newOvhClient(consumerKey) {
  let client = ovh({
    endpoint: "ovh-eu",
    appKey: env.get("APP_KEY").asString(),
    appSecret: env.get("APP_SECRET").asString(),
    ...(consumerKey ? { consumerKey } : {}),
  });
  return client;
}

export async function getClient(key) {
  if (key) {
    return newOvhClient(key);
  }

  let client = newOvhClient();
  let { consumerKey, validationUrl, ...rest } = await client.requestPromised("POST", "/auth/credential", {
    accessRules: [
      { method: "POST", path: "/auth/*" },
      { method: "GET", path: "/ip" },
      { method: "GET", path: "/ip/*" },
      { method: "PUT", path: "/ip/*" },
      { method: "POST", path: "/ip/*" },
      { method: "DELETE", path: "/ip/*" },
      { method: "GET", path: "/dedicated/*" },
      { method: "POST", path: "/dedicated/*" },
      { method: "GET", path: "/vps" },
      { method: "GET", path: "/vps/*" },
      { method: "GET", path: "/cloud" },
      { method: "GET", path: "/cloud/*" },
    ],
  });

  console.log(`Waiting 20 sec for the key ${consumerKey} to be validated...`);
  await open(validationUrl);

  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(newOvhClient(consumerKey));
    }, 20000);
  });
}
