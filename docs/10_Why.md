## I wrote it because ...

I had a need. I have several projects - kind of apps. The most of them use some low level files, scripts, stylesheets, classes that are located in their atomic project folders.

I wanted to have a helper that can deploy changes of an atomic but shared project to all applications that embed it.

In database language: a relation betwenn n sources and m targets.
It works in both directions.

### Usage of a source

```mermaid
flowchart LR

    subgraph Low level sources
        P1(Project 1: a script)
        P2(Project 2: a class)
        P3(Project 3: another class)
        P4(Project 4: a stylesheet)
    end

    subgraph Targets
        AppA(Application A)
        AppB(Application B)
        AppC(Application C)
        AppD(Application D)
        AppE(Application E)
    end

    P2 --> AppA
    P2 --> AppB
    P2 --> AppD

    style P2 fill:#9cf,stroke:#567,stroke-width:2px
```

### Sourced items in an application

```mermaid
flowchart LR

    subgraph Low level sources
        P1(Project 1: a script)
        P2(Project 2: a class)
        P3(Project 3: another class)
        P4(Project 4: a stylesheet)
    end

    subgraph Targets
        AppA(Application A)
        AppB(Application B)
        AppC(Application C)
        AppD(Application D)
        AppE(Application E)
    end

    P1 --> AppC
    P3 --> AppC
    P4 --> AppC

    style AppC fill:#9cf,stroke:#567,stroke-width:2px
```

DSF can copy the source files, or just compare it. 
You can list all sources with all targets to get a total overview of all elements.
There is a search for the current directory - it finds its usage in sources and targets.
