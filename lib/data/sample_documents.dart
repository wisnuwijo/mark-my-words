import '../models/document_model.dart';

class SampleDocuments {
  static List<DocumentItem> getInitialDocuments() {
    return [
      DocumentItem(
        id: 'spec',
        title: 'Linear 2026 Product Spec.md',
        folder: 'specs',
        tag: 'Specs',
        content: '''# MarkMyWord — Desktop Markdown Reader

> A high-performance, keyboard-first Markdown reader crafted with macOS native design paradigms and the Linear design system.

---

## 1. Executive Summary

Modern knowledge workers and developers spend significant hours reading technical documentation, specifications, and notes in Markdown. However, most existing desktop readers are either heavy web-bloat wrappers or lack the polished craft of modern productivity software like **Linear.app**.

**MarkMyWord** bridges this gap:
- **Instantaneous launch** (< 200ms cold boot)
- **Deep native keyboard mastery** (`⌘K` command palette, `⌘1-3` view modes)
- **Pixel-perfect Linear aesthetics** with subtle 1px border glows and micro-interactions
- **Distraction-free typography** calibrated for extended reading comfort

---

## 2. Core Architecture & Requirements

```typescript
export interface DocumentSession {
  readonly id: string;
  readonly filePath: string;
  readonly byteSize: number;
  viewMode: "reader" | "split" | "source";
  readingProgress: number; // 0.0 - 1.0
  activeHeadingAnchor?: string;
}

export function calculateReadingTime(wordCount: number): string {
  const wordsPerMinute = 220;
  const minutes = Math.ceil(wordCount / wordsPerMinute);
  return `\${minutes} min read`;
}
```

### 2.1 Visual Design Principles
We adopt the precision and restraint defined by the Linear design language:
1. **Obsidian Foundation**: Deep, rich dark hues (`#08090a` to `#12141a`) with frosted glass blur.
2. **Subtle Elevation**: 1px borders with `rgba(255, 255, 255, 0.08)` and delicate inner glows.
3. **Linear Purple Accent**: Crisp indigo `#5e6ad2` utilized sparingly for intentional focus.

> [!NOTE]
> The macOS typography engine automatically activates balanced line wraps for headings and pretty line breaking for prose paragraphs to eliminate orphaned lines.

---

## 3. Product Deliverables & Checklist

Here is the implementation roadmap for the macOS client:

- [x] High-fidelity HTML mockup conforming to Linear design system
- [x] Responsive macOS Titlebar with integrated segmented controls
- [x] Command Palette (`⌘K`) with fuzzy navigation
- [x] Flutter macOS Desktop client with native performance
- [ ] File system watcher for instant hot-reload on file edits
- [ ] Export engine (PDF print styling, clean HTML, rich text)

---

## 4. Benchmark Comparison

| Attribute | Legacy Electron Readers | Native Lightweight Shell |
| :--- | :--- | :--- |
| **Memory Footprint** | 280MB – 450MB | **18MB – 35MB** |
| **Startup Latency** | 1.8s – 3.2s | **< 150ms** |
| **Command Palette** | Inconsistent | **Instant (`⌘K`)** |
| **macOS Native Feel** | Emulated | **True Cocoa / Metal Chrome** |

---

## 5. Architectural Flow & Pipeline

The reading engine operates in a reactive pipeline from local disk directly to the hardware accelerated canvas:

```mermaid
flowchart LR
    A["Disk (.md file)"] --> B["Memory Stream"]
    B --> C["Fast AST Tokenizer"]
    C --> D{"AST Dispatcher"}
    D -->|"Mermaid Syntax"| E["Vector SVG Renderer"]
    D -->|"GFM Prose"| F["Hardware Canvas"]
    E --> G["Smooth 120fps View"]
    F --> G
```

> [!TIP]
> You can open any Markdown file from your Mac using `⌘O` or the File button!
''',
      ),
      DocumentItem(
        id: 'architecture',
        title: 'macOS Architecture & Engine.md',
        folder: 'engineering',
        tag: 'Tech',
        content: '''# macOS Architecture & Engine Specs

An overview of the runtime engine and file synchronization model for the macOS reader.

## 1. Zero-Copy File Streaming
When opening multi-megabyte markdown files, the app utilizes file memory mapping (`mmap`) to prevent allocation spikes.

```rust
pub struct MarkdownReader {
    buffer_pool: Vec<u8>,
    ast_cache: LruCache<String, DocumentNode>,
}

impl MarkdownReader {
    pub fn stream_from_path(path: &Path) -> Result<Self, IOError> {
        // Zero-copy memory mapping
        let file = File::open(path)?;
        let mmap = unsafe { Mmap::map(&file)? };
        Ok(Self::new(mmap))
    }
}
```

## 2. Ingestion & Event Sequence

```mermaid
sequenceDiagram
    autonumber
    actor User as Mac User
    participant Shell as macOS App Shell
    participant Engine as MMW Engine
    participant UI as Linear Renderer

    User->>Shell: Open .md File
    Shell->>Engine: Stream file descriptor (mmap)
    Engine->>Engine: Tokenize GFM + Mermaid AST
    Engine-->>UI: Dispatched virtual tree
    UI->>User: Instant render (< 16ms)
```

## 3. Typography & Layout Metrics
- **Base Body**: 15px with 1.68 line-height
- **Code Block**: JetBrains Mono 13px with 1.6 line-height
- **Active Section Spy**: Throttled to 60fps with requestAnimationFrame

> [!TIP]
> Use Split Mode (`⌘2`) to inspect side-by-side edits in real time!
''',
      ),
      DocumentItem(
        id: 'large',
        title: 'Kubernetes Core Spec (Large 4.2 MB).md',
        folder: 'benchmarks',
        tag: 'Large',
        isLarge: true,
        content: '''# Kubernetes Core Cluster Architecture & API Specification

> **Large Document Benchmark (4.2 MB Stream)**: Testing large document memory ingestion, high-speed virtual tokenization, complex Mermaid diagrams, and Linear typography streaming.

---

## 1. System Topology Overview

Kubernetes is a portable, extensible platform for managing containerized workloads and services. When managing large clusters with thousands of pods, declarative state reconciliation is handled by control-plane controllers.

```mermaid
flowchart TD
    subgraph ControlPlane ["Control Plane (Master Node)"]
        API["kube-apiserver"]
        ETCD[("etcd Raft Ring")]
        SCHED["kube-scheduler"]
        CM["kube-controller-manager"]
        API <--> ETCD
        API <--> SCHED
        API <--> CM
    end

    subgraph WorkerNodes ["Worker Nodes (Pool of 500 Nodes)"]
        KUBELET1["kubelet agent"]
        PROXY1["kube-proxy"]
        CONTAINER1["Container Runtime"]
        KUBELET1 --> CONTAINER1
        API <==>|"gRPC Stream"| KUBELET1
    end

    Client(["kubectl / Helm CLI"]) --> API
```

---

## 2. Cluster State Machine Workflow

```mermaid
stateDiagram-v2
    [*] --> DesiredStateObserved: YAML Manifest
    DesiredStateObserved --> DiffComputation: Reconciler triggers
    DiffComputation --> CreatingResources: Spec != Status
    DiffComputation --> InSync: Spec == Status
    CreatingResources --> HealthProbing: Pod scheduling
    HealthProbing --> InSync: Readiness checks pass
    HealthProbing --> BackoffRetry: CrashLoopBackOff
    BackoffRetry --> CreatingResources: Exponential retry
    InSync --> [*]
```

---

## 3. Production Workload Metrics (50,000 Containers)

| Component | Target Latency (p99) | Ingress Bandwidth | Node CPU Quota | Memory Buffer |
| :--- | :--- | :--- | :--- | :--- |
| **kube-apiserver** | < 12ms | 4.8 Gbps | 16 Cores | 32 GB ECC |
| **etcd Raft Ring** | < 3ms | 1.2 Gbps | 8 Cores | 16 GB NVMe |
| **kube-scheduler** | < 25ms | 600 Mbps | 4 Cores | 8 GB |
| **CNI Mesh (Cilium)** | < 0.8ms | 40 Gbps | 8 Cores | 12 GB eBPF |

---

## 4. Control Plane gRPC Gateway Engine

```rust
pub struct ClusterController<C: ClientInterface> {
    apiserver_client: Arc<C>,
    watch_cache: DashMap<ResourceKey, VersionedObject>,
    worker_queue: PriorityQueue<ReconcileRequest>,
}

impl<C: ClientInterface> ClusterController<C> {
    pub async fn run_reconciliation_loop(&self) -> Result<(), ClusterError> {
        while let Some(request) = self.worker_queue.pop().await {
            let current = self.apiserver_client.get(&request.key).await?;
            if current.generation != request.observed_generation {
                self.sync_state(request.key, current).await?;
            }
        }
        Ok(())
    }
}
```

> [!TIP]
> Notice how smoothly the macOS reader handles this heavy multi-diagram specification without UI freeze or dropped frames!
''',
      ),
      DocumentItem(
        id: 'design',
        title: 'Linear Design System Tokens.md',
        folder: 'design-system',
        tag: 'Design',
        content: '''# Linear Design System Tokens

Guidelines and token values extracted directly from Linear's desktop design system.

## 1. Color Palette
- **Obsidian Dark**: `#08090a` (Canvas)
- **Surface**: `#12141a` (Cards, Panels)
- **Elevated**: `#181a22` (Popovers, Modals)
- **Linear Indigo**: `#5e6ad2` (Key interactive state)

## 2. Interaction Model
Every action has an intuitive single-keystroke or combo shortcut. Micro-interactions utilize spring-like cubic beziers.

- [x] Contrast ratio verified WCAG AAA (7.2:1)
- [x] Sub-pixel antialiasing tuned for Retina displays
''',
      ),
      DocumentItem(
        id: 'changelog',
        title: 'CHANGELOG.md',
        folder: 'root',
        content: '''# Changelog

All notable changes to **MarkMyWord** are documented here.

## [v0.1.0] - 2026-10-06
### Added
- Native macOS Flutter desktop shell with Cocoa titlebar
- Linear obsidian UI theme with custom accent glows
- Command Palette (`⌘K`) with fuzzy navigation
- Interactive Mermaid vector diagram rendering
- Subtle loading laser shimmer and stream indicator
- Dynamic Table of Contents outline panel
- Interactive markdown checklists
''',
      ),
      DocumentItem(
        id: 'readme',
        title: 'README.md',
        folder: 'root',
        content: '''# MarkMyWord

A lightweight, distraction-free Markdown reader built for macOS.

### Quick Start
1. Press `⌘O` to open any Markdown file.
2. Press `⌘K` to open the command palette.
3. Press `⌘1`, `⌘2`, or `⌘3` to switch views.
''',
      ),
    ];
  }
}
