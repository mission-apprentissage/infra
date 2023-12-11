async function resourceExists(client, sendRequest) {
  try {
    await sendRequest();
    return true;
  } catch (e) {
    if (e.error === 404) {
      return false;
    }
    console.error(e);
    throw new Error('Error from OVH API');
  }
}

async function resourceOrNull(client, sendRequest) {
  try {
    const result = await sendRequest();
    return result;
  } catch (e) {
    if (e.error === 404) {
      return null;
    }
    console.error(e);
    throw new Error('Error from OVH API');
  }
}

function waitReady(callback, options = {}) {
  return new Promise((resolve, reject) => {
    let retries = 0;

    async function retry(delay, maxRetries) {
      try {
        await callback();
        resolve();
      } catch (e) {
        if (retries++ > maxRetries) {
          reject(e);
        } else {
          console.log(`Not yet ready. Retrying in ${delay}ms...`);
          setTimeout(() => retry(delay, maxRetries), delay);
        }
      }
    }

    retry(options.delay || 5000, options.maxRetries || 24); // Try every 5 seconds and wait for 2 minutes max
  });
}

module.exports = {
  resourceExists,
  waitReady,
  resourceOrNull,
};
