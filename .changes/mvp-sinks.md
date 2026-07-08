---
bump: minor
category: Features
---

Sinks for every MVP destination: `CallbackSink` (hand records to any function, e.g. an in-app log viewer), `FileSink` (JSON-lines log files on Lute), `TransportSink` (buffered batches for external logging platforms), and a `JsonFormatter` backed by each runtime's native JSON encoder.
