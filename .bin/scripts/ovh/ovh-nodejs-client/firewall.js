const { resourceExists, resourceOrNull } = require("./utils");

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

const allowTcpOnPort = (sequence, port) => {
  return {
    sequence,
    action: "permit",
    protocol: "tcp",
    destinationPort: port,
    source: null,
    sourcePort: null,
    tcpOption: {},
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

// Rule definition doesn't have same shape as the rule object
const ruleNeedsUpdate = (def, currentRule = null) => {
  const defTcpOption = def.tcpOption?.option ?? null;
  const defDestPort = def.destinationPort ? `eq ${def.destinationPort}` : def.destinationPort;
  return (
    currentRule === null ||
    def.sequence !== currentRule.sequence ||
    def.action !== currentRule.action ||
    def.protocol !== currentRule.protocol ||
    currentRule.state !== "ok" ||
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
    return client.request("GET", `/ip/${ipBlock}/firewall/${ip}`);
  });
}

async function getRule(client, ip, sequence) {
  return resourceOrNull(client, () => {
    let ipBlock = asIpBlock(ip);
    return client.request("GET", `/ip/${ipBlock}/firewall/${ip}/rule/${sequence}`);
  });
}

async function mitigationActivated(client, ip) {
  return resourceExists(client, () => {
    let ipBlock = asIpBlock(ip);
    return client.request("GET", `/ip/${ipBlock}/mitigation/${ip}`);
  });
}

async function createFirewall(client, ip) {
  let ipBlock = asIpBlock(ip);

  if (await firewallExists(client, ip)) {
    console.log(`Firewall already created for ip '${ip}'`);
    return;
  }
  console.log(`Creating firewall for ip '${ip}'...`);
  return client.request("POST", `/ip/${ipBlock}/firewall`, { ipOnFirewall: ip });
}

async function updateRule(client, ip, def) {
  let ipBlock = asIpBlock(ip);

  const currentRule = await getRule(client, ip, def.sequence);
  if (currentRule) {
    if (!ruleNeedsUpdate(def, currentRule)) {
      return;
    }

    console.log("Removing rule", currentRule);
    await client.request("DELETE", `/ip/${ipBlock}/firewall/${ip}/rule/${currentRule.sequence}`);
    console.log("Waiting 60s for rule to be removed");
    await new Promise((resolve) => setTimeout(resolve, 60_000));
  }

  console.log(`Creating rule`, def);
  await client.request("POST", `/ip/${ipBlock}/firewall/${ip}/rule`, def);
}

async function updateRules(client, ip, defs) {
  let ipBlock = asIpBlock(ip);

  const existingSequence = await client.request("GET", `/ip/${ipBlock}/firewall/${ip}/rule`);
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
        return client.request("DELETE", `/ip/${ipBlock}/firewall/${ip}/rule/${s}`);
      })
  );

  await Promise.all(tasks);
}

async function configureFirewall(client, ip) {
  await createFirewall(client, ip);
  await updateRules(client, ip, [
    allowTcpConnection(0),
    allowTcpOnPort(1, 22),
    allowTcpOnPort(2, 443),
    allowTcpOnPort(3, 80),
    allowICMP(10),
    denyAllTcp(19),
  ]);
  console.log(`Firewall for ${ip} configured`);
}

async function activateMitigation(client, ip) {
  let ipBlock = asIpBlock(ip);
  if (await mitigationActivated(client, ip)) {
    console.log(`Mitigation already activated for ip '${ip}'`);
    return;
  }

  console.log(`Activating permanent mitigation...`);
  await client.request("POST", `/ip/${ipBlock}/mitigation`, { ipOnMitigation: ip });
}

async function closeService(client, ip) {
  if (await firewallExists(client, ip)) {
    await updateRules(client, ip, [allowTcpConnection(0), allowTcpOnPort(1, 22), allowICMP(10), denyAllTcp(19)]);
  } else {
    console.log("Firewall does not exist, can't close service on port 443/80 !");
  }
}

async function getAllIp(client, ip) {
  const ipData = await client.request("GET", `/ip/${ip}`);
  const ips = await client.request("GET", `/vps/${ipData.routedTo.serviceName}/ips`);
  // Returns all ipv4
  return ips.filter((i) => i.includes("."));
}

module.exports = {
  configureFirewall,
  activateMitigation,
  closeService,
  getAllIp,
};
