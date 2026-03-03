function parseContainers(output) {
  if (!output) return [];
  var lines = output.split("\n").filter(function (line) {
    return line.trim() !== "";
  });
  var results = [];

  lines.forEach(function (line) {
    try {
      var container = JSON.parse(line);
      results.push({
        id: String(container.ID || ""),
        name: String(container.Names || ""),
        image: String(container.Image || ""),
        status: String(container.Status || ""),
        state: String(container.State || "unknown"),
        ports: String(container.Ports || ""),
        created: String(container.CreatedAt || ""),
      });
    } catch (e) {
      console.warn("Error parsing container:", e);
    }
  });
  return results;
}

function parseImages(output, runningContainers) {
  if (!output) return [];
  var lines = output.split("\n").filter(function (line) {
    return line.trim() !== "";
  });
  var results = [];

  lines.forEach(function (line) {
    try {
      var image = JSON.parse(line);
      var repo = image.Repository || "<none>";
      var tag = image.Tag || "latest";
      var fullName = repo + ":" + tag;

      var isRunning = false;
      if (runningContainers && runningContainers.length > 0) {
        for (var i = 0; i < runningContainers.length; i++) {
          var c = runningContainers[i];
          if (c.image === fullName || c.image === repo) {
            isRunning = true;
            break;
          }
        }
      }

      results.push({
        repository: String(repo),
        tag: String(tag),
        id: String(image.ID || ""),
        size: String(image.Size || "0B"),
        created: String(image.CreatedAt || ""),
        isRunning: isRunning,
      });
    } catch (e) {
      console.warn("Error parsing image:", e);
    }
  });
  return results;
}

function parseVolumes(output) {
  if (!output) return [];
  var lines = output.split("\n").filter(function (line) {
    return line.trim() !== "";
  });
  var results = [];

  lines.forEach(function (line) {
    try {
      var vol = JSON.parse(line);
      results.push({
        name: String(vol.Name || ""),
        driver: String(vol.Driver || ""),
        mountpoint: String(vol.Mountpoint || ""),
      });
    } catch (e) {
      console.warn("Error parsing volume:", e);
    }
  });
  return results;
}

function parseNetworks(output) {
  if (!output) return [];
  var lines = output.split("\n").filter(function (line) {
    return line.trim() !== "";
  });
  var results = [];

  lines.forEach(function (line) {
    try {
      var net = JSON.parse(line);
      var name = String(net.Name || "");

      var isDefault = name === "bridge" || name === "host" || name === "none";

      results.push({
        name: name,
        id: String(net.ID || ""),
        driver: String(net.Driver || ""),
        scope: String(net.Scope || ""),
        isDefault: isDefault,
      });
    } catch (e) {
      console.warn("Error parsing network:", e);
    }
  });
  return results;
}

function parseExposedPorts(inspectJsonString) {
  try {
    var data = JSON.parse(inspectJsonString);
    if (
      data &&
      data.length > 0 &&
      data[0].Config &&
      data[0].Config.ExposedPorts
    ) {
      var ports = Object.keys(data[0].Config.ExposedPorts);
      if (ports.length > 0) {
        return ports[0].split("/")[0];
      }
    }
  } catch (e) {
    console.warn("Error parsing inspect:", e);
  }
  return null;
}

function getStatusColor(state) {
  if (!state) return "#ffffff";
  switch (state) {
    case "running":
      return "#4caf50";
    case "paused":
      return "#ff9800";
    case "exited":
      return "#f44336";
    case "dead":
      return "#9e9e9e";
    default:
      return "#ffffff";
  }
}

function guessDefaultPort(repoName) {
  if (!repoName) return "8080";
  var repo = repoName.toLowerCase();
  if (repo.includes("mongo")) return "27017";
  if (repo.includes("postgres")) return "5432";
  if (repo.includes("redis")) return "6379";
  if (repo.includes("mysql") || repo.includes("mariadb")) return "3306";
  if (
    repo.includes("nginx") ||
    repo.includes("apache") ||
    repo.includes("httpd")
  )
    return "80";
  if (repo.includes("node") || repo.includes("react") || repo.includes("npm"))
    return "3000";
  return "8080";
}
