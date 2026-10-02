# External GUI interface: initial design (parked)

A generic interface that lets a fully external GUI read a model and follow a
running simulation. It serves the descriptors the inspector reads
(`inspector.md` in this folder) plus runtime data through subscriptions.
Parked on 2026-09-28, when the inspector session split it off. Nothing here
is settled yet.

## Pending Questions

1. **Subscription.** What does a subscriber name: paths, faces, whole
   snapshots? At what rate, with what timestamps, and what happens to a slow
   client?
2. **Writes and control.** Does the interface carry staged writes, making an
   external client a device with a claim, and control-plane commands such as
   run, pause and stop?
3. **Transport.** In-process server device, WebSocket or something else, how
   many clients, remote or local only?
4. **Value type schema.** A subscriber decoding a stream of values needs each
   face type's layout: field names, element types, nesting. The inspector
   needs only type names. What schema does the interface add to the
   descriptor?
5. **Validating the runtime half.** What proves it works: a reference client,
   a conformance suite, both?
6. **Packaging.** Which package holds the interface?

## Answered Questions

None yet. Two answers from the inspector session bind this piece too:

- **No graphical authoring, ever.** No client writes model structure through
  the interface.
- **Independence.** The core never depends on the interface.

## Constraints inherited from the inspector

The inspector designs the descriptor first. It keeps three properties on this
interface's behalf:

- **Canonical addressing.** Descriptors name components by slash path and
  faces by face name (§8.6), the names a subscription would use.
- **Transport independence.** A descriptor is a self-contained document that
  works as a file or as a message.
- **Additive versioning.** A descriptor version may add content without
  breaking existing readers, so a value type schema can be added here later.

The core entry point that writes descriptors is shared. Whatever the
inspector settles for it, this interface calls it too.

## Design Axes

Not drawn yet.

## Glossary

- **External interface.** The generic surface through which a GUI outside the
  simulation reads descriptors and subscribes to runtime data.
- **Subscription.** An external client's standing request for runtime data
  from a running simulation.
