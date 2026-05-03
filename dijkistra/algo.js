const graph = {
  A: { lng: 35.9106, lat: 31.9539, neighbors: { B: 12, C: 20 } },
  B: { lng: 35.8200, lat: 32.1000, neighbors: { A: 12, D: 30 } },
  C: { lng: 35.7000, lat: 32.3000, neighbors: { A: 20, D: 18 } },
  D: { lng: 35.5000, lat: 32.7000, neighbors: { B: 30, C: 18, E: 35 } },
  E: { lng: 35.3000, lat: 33.2000, neighbors: { D: 35, F: 25 } },
  F: { lng: 35.1863, lat: 33.5723, neighbors: { E: 25 } }
};

function dijkstra(graph, start, end) {
  const distances = {};
  const previous = {};
  const visited = new Set();

  for (let node in graph) {
    distances[node] = Infinity;
    previous[node] = null;
  }

  distances[start] = 0;

  while (true) {
    let current = null;

    for (let node in graph) {
      if (!visited.has(node)) {
        if (current === null || distances[node] < distances[current]) {
          current = node;
        }
      }
    }

    if (current === null) break;
    if (current === end) break;

    visited.add(current);

    for (let neighbor in graph[current].neighbors) {
      const distance = graph[current].neighbors[neighbor];
      const newDistance = distances[current] + distance;

      if (newDistance < distances[neighbor]) {
        distances[neighbor] = newDistance;
        previous[neighbor] = current;
      }
    }
  }

  const path = [];
  let node = end;

  while (node !== null) {
    path.unshift(node);
    node = previous[node];
  }

  return {
    distanceKm: distances[end],
    path
  };
}

const result = dijkstra(graph, "A", "F");

console.log(result);

