![](assets/banner.png){ align=left; loading=lazy; style="width:auto;max-height:600px;"}

# Plant-it Enhanced

Plant-it Enhanced is a maintained, self-hosted gardening and field-journal companion. It combines
everyday-name plant search, source-aware care guidance, reminders, photo identification, and a
private hiking journal in one AMD64/ARM64 container image.

## Highlights

- Search common names, aliases, scientific names, and minor misspellings.
- Use a bundled plant and care catalog without any cloud API key.
- Inspect whole-catalog coverage and private, locally observed quality gaps.
- Optionally identify a plant from guided whole-plant, leaf, and flower photos.
- Optionally select a closer regional flora from a coarsened, opt-in field location.
- Compare attributable trail lookalikes and source-backed habitat/elevation evidence.
- Review where each care value came from and how confident the source is.
- Review separately sourced safety guidance for people, cats, and dogs without treating unknown as
  safe.
- Use a private guided health check and an honest manual light-placement estimate with Extension
  references.
- Track owned plants, care events, reminders, snoozes, and upcoming work.
- Save private trail observations offline, group them into hikes, and retry interrupted sync safely.
- Keep MySQL, Redis, uploads, provider keys, exact coordinates, and original photos on your server.
- Deploy cleanly behind Cloudflare Tunnel and Nginx Proxy Manager without publishing app, database,
  or cache ports on the NAS.

Start with [Server installation](server-installation.md), then connect a browser or mobile device
using [App installation](app-installation.md). See [Features](features.md) for the complete workflow.

!!! warning "Wild-plant safety"

    Identification results are suggestions. Never eat, touch, or use a wild plant medicinally
    based on an app result. Compare lookalikes and follow local ranger or public-health guidance.
