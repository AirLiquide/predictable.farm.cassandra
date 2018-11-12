Predictable Farm — Cassandra instance docker files
---

### Introduction

The cassandra instance is the NoSQL DB shared by the dashboard and the automation engine.

The container exposes the following ports :

  - 7000: intra-node communication
  - 7001: TLS intra-node communication
  - 7199: JMX
  - 9042: CQL
  - 9160: thrift service

#### Build (using docker)

    docker build .

### License

MIT. See License.txt file