import getConfig from "./getConfig.js";
import { resourceExists, resourceOrNull } from "./utils.js";

const allowTcpConnection = (sequence) => {
  return {
    sequence,
    action: "permit",
    protocol: "tcp",
    source: null,
    sourcePort: null,
    destinationPort: null,
    tcpOption: { option: "established" },
  };
};

const allowTcpOnPort = (sequence, port, source = null) => {
  return {
    sequence,
    action: "permit",
    protocol: "tcp",
    destinationPort: port,
    source,
    sourcePort: null,
    tcpOption: {},
  };
};
const allowUdpOnPort = (sequence, port) => {
  return {
    sequence,
    action: "permit",
    protocol: "udp",
    destinationPort: port,
    source: null,
    sourcePort: null,
  };
};
const allowICMP = (sequence) => {
  return {
    sequence,
    protocol: "icmp",
    action: "permit",
    source: null,
    sourcePort: null,
    destinationPort: null,
  };
};
const denyAllTcp = (sequence) => {
  return {
    sequence,
    action: "deny",
    protocol: "tcp",
    source: null,
    sourcePort: null,
    destinationPort: null,
    tcpOption: {},
  };
};
const denyAllUdp = (sequence) => {
  return {
    sequence,
    action: "deny",
    protocol: "udp",
    source: null,
    sourcePort: null,
    destinationPort: null,
  };
};

// Rule definition doesn't have same shape as the rule object
const ruleNeedsUpdate = (def, currentRule = null) => {
  const defTcpOption = def.tcpOption?.option ?? null;
  const defDestPort = def.destinationPort ? `eq ${def.destinationPort}` : def.destinationPort;
  return (
    currentRule === null ||
    def.sequence !== currentRule.sequence ||
    def.action !== currentRule.action ||
    def.protocol !== currentRule.protocol ||
    !["ok", "creationPending"].includes(currentRule.state) ||
    def.sourcePort !== currentRule.sourcePort ||
    defDestPort !== currentRule.destinationPort ||
    currentRule.fragments ||
    defTcpOption !== currentRule.tcpOption
  );
};

function asIpBlock(ip) {
  const mask = ip.includes(":") ? 128 : 32;
  return encodeURIComponent(`${ip}/${mask}`);
}

async function firewallExists(client, ip) {
  return resourceExists(client, () => {
    let ipBlock = asIpBlock(ip);
    return client.requestPromised("GET", `/ip/${ipBlock}/firewall/${ip}`);
  });
}

async function getRule(client, ip, sequence) {
  return resourceOrNull(client, () => {
    let ipBlock = asIpBlock(ip);
    return client.requestPromised("GET", `/ip/${ipBlock}/firewall/${ip}/rule/${sequence}`);
  });
}

async function mitigationActivated(client, ip) {
  return resourceExists(client, () => {
    let ipBlock = asIpBlock(ip);
    return client.requestPromised("GET", `/ip/${ipBlock}/mitigation/${ip}`);
  });
}

async function createFirewall(client, ip) {
  let ipBlock = asIpBlock(ip);

  if (await firewallExists(client, ip)) {
    console.log(`Firewall already created for ip '${ip}'`);
    return;
  }
  console.log(`Creating firewall for ip '${ip}'...`);
  return client.requestPromised("POST", `/ip/${ipBlock}/firewall`, { ipOnFirewall: ip });
}

async function updateRule(client, ip, def) {
  let ipBlock = asIpBlock(ip);

  const currentRule = await getRule(client, ip, def.sequence);
  if (currentRule) {
    if (!ruleNeedsUpdate(def, currentRule)) {
      return;
    }

    console.log("Removing rule", currentRule);
    await client.requestPromised("DELETE", `/ip/${ipBlock}/firewall/${ip}/rule/${currentRule.sequence}`);
    console.log("Waiting 60s for rule to be removed");
    await new Promise((resolve) => setTimeout(resolve, 60_000));
  }

  console.log(`Creating rule`, def);
  await client.requestPromised("POST", `/ip/${ipBlock}/firewall/${ip}/rule`, def);
}

async function updateRules(client, ip, defs) {
  let ipBlock = asIpBlock(ip);

  const existingSequence = await client.requestPromised("GET", `/ip/${ipBlock}/firewall/${ip}/rule`);
  const expectedSequence = new Set(defs.map((def) => def.sequence));

  const tasks = [];
  for (let i = 0; i < defs.length; i++) {
    tasks.push(updateRule(client, ip, defs[i]));
  }
  tasks.push(
    ...existingSequence
      .filter((s) => !expectedSequence.has(Number(s)))
      .map(async (s) => {
        console.log("Removing rule", await getRule(client, ip, s));
        return client.requestPromised("DELETE", `/ip/${ipBlock}/firewall/${ip}/rule/${s}`);
      })
  );

  await Promise.all(tasks);
}

async function updateIpDescription(client, ip, product, env) {
  const resp = await client.requestPromised("GET", `/ip/${asIpBlock(ip)}`);
  const description = `${product}-${env}`;
  if (resp.description !== description) {
    await client.requestPromised("PUT", `/ip/${asIpBlock(ip)}`, { description: description });
  }
}

async function configureFirewall(client, ip, product, env) {
  await updateIpDescription(client, ip, product, env);

  await createFirewall(client, ip);
  const rules = [
    allowTcpConnection(0),
    allowTcpOnPort(1, 22),
    allowTcpOnPort(2, 443),
    allowTcpOnPort(3, 80),
    allowICMP(10),
    // denyAllUdp(18),
    denyAllTcp(19),
  ];

  if (product === "mongodb") {
    const config = await getConfig();
    const sources = [...config["vpn-production"]];
    if (env.startsWith("recette")) {
      const keys = Object.keys(config).filter((key) => key.endsWith("recette"));
      sources.push(...keys.map((key) => config[key]).flat());
    }
    if (env.startsWith("bal")) {
      sources.push(config["bal-production"]);
    }
    if (env.startsWith("contrat")) {
      sources.push(config["contrat-production"]);
    }

    sources.forEach((source, i) => {
      let n = i + 4;
      if (n >= 10) {
        // Avoid conflict with existing rules 10
        n++;
      }

      rules.push(allowTcpOnPort(n, 27017, `${source}/32`));
    });
  }

  if (product === "monitoring") {
    rules.push(allowTcpOnPort(4, 444));
  }

  await updateRules(client, ip, rules);
  console.log(`Firewall for ${ip} configured`);
}

async function activateMitigation(client, ip) {
  let ipBlock = asIpBlock(ip);
  if (await mitigationActivated(client, ip)) {
    console.log(`Mitigation already activated for ip '${ip}'`);
    return;
  }

  console.log(`Activating permanent mitigation...`);
  await client.requestPromised("POST", `/ip/${ipBlock}/mitigation`, { ipOnMitigation: ip });
}

async function closeService(client, ip) {
  if (await firewallExists(client, ip)) {
    await updateRules(client, ip, [allowTcpConnection(0), allowTcpOnPort(1, 22), allowICMP(10), denyAllTcp(19)]);
  } else {
    console.log("Firewall does not exist, can't close service on port 443/80 !");
  }
}

async function getAllIp(client, ip, product) {
  const ipData = await client.requestPromised("GET", `/ip/${ip}`);
  
  if (product === "mongodb") {
    const instances = await client.requestPromised("GET", `/cloud/project/${ipData.routedTo.serviceName}/instance`);
    const instance = instances.find(instance => instance.ipAddresses.some(i => i.ip === ip));

    if (!instance) {
      throw new Error(`Instance not found for ip ${ip}`);
    }

    return instance.ipAddresses
      .filter(i => i.version === 4 && i.type === "public")
      .map(i => i.ip);
  }
    
  const ips = await client.requestPromised("GET", `/vps/${ipData.routedTo.serviceName}/ips`);

  // Returns all ipv4
  return ips.filter((i) => i.includes(".") && !i.startsWith("10."));
}

export { configureFirewall, activateMitigation, closeService, getAllIp };
