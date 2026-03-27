import "./styles.css";

import {
  generatorIndex,
  prototypeCatalog,
  prototypeStage,
  shieldIndex,
  sidekickIndex,
} from "./game/data";
import { maxWeaponPower, nextWeaponUpgradeCost, slotLabel } from "./game/economy";
import { InputState } from "./game/input";
import { Renderer } from "./game/render";
import { Simulation, WORLD_HEIGHT, WORLD_WIDTH } from "./game/simulation";
import type { RunState, ShopSection, StageOutcome, UpgradeCatalog, UpgradeSlot } from "./game/types";

type Screen = "briefing" | "stage" | "shop" | "destroyed";

const DEFAULT_RUN_STATE: RunState = {
  sortie: 1,
  credits: 680,
  earnedThisSortie: 0,
  loadout: {
    frontWeaponId: "pulse-lance",
    rearWeaponId: "tail-array",
    shieldId: "mesh-i",
    generatorId: "reactor-i",
    leftSidekickId: "empty",
    rightSidekickId: "empty",
    frontPower: 1,
    rearPower: 1,
    rearModeIndex: 0,
  },
};

const app = document.querySelector<HTMLDivElement>("#app");

if (!app) {
  throw new Error("Missing app root");
}

app.innerHTML = `
  <div class="shell">
    <aside class="sidebar">
      <div class="hud-card">
        <p class="eyebrow">Rewrite Prototype</p>
        <h1>Wireframe Sortie</h1>
        <p class="lede">A clean browser rewrite of the Tyrian loop: one combat stage, one shop, and a persistent six-slot loadout.</p>
      </div>
      <div class="hud-card" id="hud"></div>
      <div class="hud-card" id="legend">
        <p class="eyebrow">Controls</p>
        <dl class="legend-grid">
          <div><dt>Move</dt><dd>Arrow keys</dd></div>
          <div><dt>Fire</dt><dd>Space</dd></div>
          <div><dt>Rear Mode</dt><dd>Enter</dd></div>
          <div><dt>Left Sidekick</dt><dd>Left/Right Ctrl</dd></div>
          <div><dt>Right Sidekick</dt><dd>Left/Right Alt</dd></div>
        </dl>
      </div>
    </aside>
    <section class="stage-shell">
      <canvas id="game-canvas"></canvas>
      <div id="overlay" class="overlay"></div>
    </section>
  </div>
`;

const canvasNode = document.querySelector<HTMLCanvasElement>("#game-canvas");
const overlayNode = document.querySelector<HTMLDivElement>("#overlay");
const hudNode = document.querySelector<HTMLDivElement>("#hud");

if (!canvasNode || !overlayNode || !hudNode) {
  throw new Error("Missing UI nodes");
}

const contextNode = canvasNode.getContext("2d");
if (!contextNode) {
  throw new Error("Could not acquire 2D context");
}

const input = new InputState();
const canvas = canvasNode;
const overlay = overlayNode;
const hud = hudNode;
const context = contextNode;
const renderer = new Renderer(canvas, context);

let screen: Screen = "briefing";
let runState = structuredClone(DEFAULT_RUN_STATE);
let simulation: Simulation | null = null;
let lastOutcome: StageOutcome | null = null;
let lastFrame = performance.now();
let accumulator = 0;
const fixedStep = 1 / 120;

function resetRunState(): void {
  runState = structuredClone(DEFAULT_RUN_STATE);
  lastOutcome = null;
  simulation = null;
}

function beginSortie(): void {
  runState.earnedThisSortie = 0;
  simulation = new Simulation(runState, prototypeStage);
  screen = "stage";
  overlay.innerHTML = "";
}

function restartCampaign(): void {
  resetRunState();
  screen = "briefing";
  renderBriefing();
}

function completeSortie(outcome: StageOutcome): void {
  lastOutcome = outcome;
  if (outcome.kind === "cleared") {
    screen = "shop";
    renderShop();
    return;
  }

  screen = "destroyed";
  renderDestroyed();
}

function stageCard(title: string, body: string, actions: string): string {
  return `
    <section class="panel">
      <p class="eyebrow">Sortie ${runState.sortie}</p>
      <h2>${title}</h2>
      <p class="lede">${body}</p>
      <div class="button-row">${actions}</div>
    </section>
  `;
}

function renderBriefing(): void {
  overlay.innerHTML = stageCard(
    prototypeStage.name,
    "Push through a single authored attack lane, cash out credits from destroyed targets, and spend them in the between-sortie hangar.",
    `
      <button class="action action-primary" data-action="launch">Launch Sortie</button>
      <button class="action" data-action="reset">Reset Loadout</button>
    `,
  );
}

function renderDestroyed(): void {
  const earned = lastOutcome?.earned ?? 0;
  overlay.innerHTML = stageCard(
    "Hull Breach",
    `You lost the run with ${earned} credits banked this sortie. This prototype resets the campaign on destruction so the loop stays sharp and readable.`,
    `
      <button class="action action-primary" data-action="restart-campaign">Restart Campaign</button>
      <button class="action" data-action="briefing">Back To Briefing</button>
    `,
  );
}

function slotCurrentId(slot: UpgradeSlot): string {
  switch (slot) {
    case "front":
      return runState.loadout.frontWeaponId;
    case "rear":
      return runState.loadout.rearWeaponId;
    case "shield":
      return runState.loadout.shieldId;
    case "generator":
      return runState.loadout.generatorId;
    case "leftSidekick":
      return runState.loadout.leftSidekickId;
    case "rightSidekick":
      return runState.loadout.rightSidekickId;
  }
}

function setSlotCurrentId(slot: UpgradeSlot, itemId: string): void {
  switch (slot) {
    case "front":
      runState.loadout.frontWeaponId = itemId;
      break;
    case "rear":
      runState.loadout.rearWeaponId = itemId;
      break;
    case "shield":
      runState.loadout.shieldId = itemId;
      break;
    case "generator":
      runState.loadout.generatorId = itemId;
      break;
    case "leftSidekick":
      runState.loadout.leftSidekickId = itemId;
      break;
    case "rightSidekick":
      runState.loadout.rightSidekickId = itemId;
      break;
  }
}

function shopSections(catalog: UpgradeCatalog): Array<ShopSection<unknown>> {
  return [
    { title: "Front Weapon", slot: "front", currentId: runState.loadout.frontWeaponId, items: catalog.frontWeapons },
    { title: "Rear Weapon", slot: "rear", currentId: runState.loadout.rearWeaponId, items: catalog.rearWeapons },
    { title: "Shield", slot: "shield", currentId: runState.loadout.shieldId, items: catalog.shields },
    { title: "Generator", slot: "generator", currentId: runState.loadout.generatorId, items: catalog.generators },
    { title: "Left Sidekick", slot: "leftSidekick", currentId: runState.loadout.leftSidekickId, items: catalog.sidekicks },
    { title: "Right Sidekick", slot: "rightSidekick", currentId: runState.loadout.rightSidekickId, items: catalog.sidekicks },
  ];
}

function renderShop(): void {
  const earned = lastOutcome?.earned ?? 0;
  const frontUpgradePrice = nextWeaponUpgradeCost(
    prototypeCatalog.frontWeapons.find((item) => item.id === runState.loadout.frontWeaponId)?.basePrice ?? 0,
    runState.loadout.frontPower,
  );
  const rearUpgradePrice = nextWeaponUpgradeCost(
    prototypeCatalog.rearWeapons.find((item) => item.id === runState.loadout.rearWeaponId)?.basePrice ?? 0,
    runState.loadout.rearPower,
  );

  const sections = shopSections(prototypeCatalog)
    .map((section) => {
      const items = section.items
        .map((item) => {
          const typedItem = item as { id: string; name: string; basePrice: number };
          const owned = section.currentId === typedItem.id;
          const afford = runState.credits >= typedItem.basePrice;
          return `
            <button
              class="shop-item ${owned ? "is-owned" : ""}"
              data-action="equip"
              data-slot="${section.slot}"
              data-item="${typedItem.id}"
              ${owned || !afford ? "disabled" : ""}
            >
              <span>${typedItem.name}</span>
              <strong>${owned ? "EQUIPPED" : `${typedItem.basePrice} cr`}</strong>
            </button>
          `;
        })
        .join("");

      return `
        <section class="shop-section">
          <div class="shop-section-head">
            <p class="eyebrow">${section.title}</p>
            <span class="shop-current">${section.currentId}</span>
          </div>
          <div class="shop-grid">${items}</div>
        </section>
      `;
    })
    .join("");

  overlay.innerHTML = `
    <section class="panel panel-wide">
      <p class="eyebrow">Hangar</p>
      <h2>Upgrade Between Sorties</h2>
      <p class="lede">Stage cleared. You banked ${earned} credits this run and now have ${runState.credits} credits ready to spend.</p>
      <div class="upgrade-bar">
        <button class="action" data-action="upgrade-front" ${runState.loadout.frontPower >= maxWeaponPower() || runState.credits < frontUpgradePrice ? "disabled" : ""}>
          Front Power ${runState.loadout.frontPower}/${maxWeaponPower()} · ${frontUpgradePrice} cr
        </button>
        <button class="action" data-action="upgrade-rear" ${runState.loadout.rearPower >= maxWeaponPower() || runState.credits < rearUpgradePrice ? "disabled" : ""}>
          Rear Power ${runState.loadout.rearPower}/${maxWeaponPower()} · ${rearUpgradePrice} cr
        </button>
      </div>
      <div class="shop-layout">${sections}</div>
      <div class="button-row">
        <button class="action action-primary" data-action="next-sortie">Continue Sortie</button>
        <button class="action" data-action="restart-campaign">Reset Campaign</button>
      </div>
    </section>
  `;
}

function renderHud(): void {
  const front = prototypeCatalog.frontWeapons.find((item) => item.id === runState.loadout.frontWeaponId);
  const rear = prototypeCatalog.rearWeapons.find((item) => item.id === runState.loadout.rearWeaponId);
  const shield = shieldIndex[runState.loadout.shieldId];
  const generator = generatorIndex[runState.loadout.generatorId];
  const leftSidekick = sidekickIndex[runState.loadout.leftSidekickId];
  const rightSidekick = sidekickIndex[runState.loadout.rightSidekickId];
  const stageTime = simulation?.stageTime ?? 0;
  const player = simulation?.player;

  hud.innerHTML = `
    <p class="eyebrow">Flight Deck</p>
    <dl class="hud-grid">
      <div><dt>Phase</dt><dd>${screen.toUpperCase()}</dd></div>
      <div><dt>Sortie</dt><dd>${runState.sortie}</dd></div>
      <div><dt>Credits</dt><dd>${runState.credits}</dd></div>
      <div><dt>Stage Time</dt><dd>${stageTime.toFixed(1)}s</dd></div>
      <div><dt>Armor</dt><dd>${player ? `${Math.ceil(player.armor)} / ${player.maxArmor}` : "90 / 90"}</dd></div>
      <div><dt>Shield</dt><dd>${player ? `${Math.ceil(player.shield)} / ${player.maxShield}` : `${shield.maxShield} max`}</dd></div>
      <div><dt>Energy</dt><dd>${player ? `${Math.ceil(player.energy)} / ${player.maxEnergy}` : `${generator.maxEnergy} max`}</dd></div>
      <div><dt>Rear Mode</dt><dd>${simulation?.rearModeLabel ?? rear?.modeA.label ?? "Trace"}</dd></div>
      <div><dt>Front</dt><dd>${front?.name} P${runState.loadout.frontPower}</dd></div>
      <div><dt>Rear</dt><dd>${rear?.name} P${runState.loadout.rearPower}</dd></div>
      <div><dt>Left</dt><dd>${leftSidekick?.name ?? "Empty"}</dd></div>
      <div><dt>Right</dt><dd>${rightSidekick?.name ?? "Empty"}</dd></div>
    </dl>
  `;
}

function handleEquip(slot: UpgradeSlot, itemId: string): void {
  const sections = shopSections(prototypeCatalog);
  const section = sections.find((entry) => entry.slot === slot);
  if (!section || slotCurrentId(slot) === itemId) {
    return;
  }

  const item = (section.items as Array<{ id: string; basePrice: number }>).find((entry) => entry.id === itemId);
  if (!item || runState.credits < item.basePrice) {
    return;
  }

  runState.credits -= item.basePrice;
  setSlotCurrentId(slot, itemId);
  renderShop();
}

function handleWeaponUpgrade(slot: "front" | "rear"): void {
  const currentId = slot === "front" ? runState.loadout.frontWeaponId : runState.loadout.rearWeaponId;
  const currentPower = slot === "front" ? runState.loadout.frontPower : runState.loadout.rearPower;
  const catalog = slot === "front" ? prototypeCatalog.frontWeapons : prototypeCatalog.rearWeapons;
  const weapon = catalog.find((entry) => entry.id === currentId);
  if (!weapon || currentPower >= maxWeaponPower()) {
    return;
  }

  const cost = nextWeaponUpgradeCost(weapon.basePrice, currentPower);
  if (runState.credits < cost) {
    return;
  }

  runState.credits -= cost;
  if (slot === "front") {
    runState.loadout.frontPower += 1;
  } else {
    runState.loadout.rearPower += 1;
  }
  renderShop();
}

overlay.addEventListener("click", (event) => {
  const target = event.target as HTMLElement | null;
  const button = target?.closest<HTMLButtonElement>("button[data-action]");
  if (!button) {
    return;
  }

  const action = button.dataset.action;
  if (action === "launch") {
    beginSortie();
    return;
  }

  if (action === "reset" || action === "briefing") {
    restartCampaign();
    return;
  }

  if (action === "restart-campaign") {
    restartCampaign();
    return;
  }

  if (action === "next-sortie") {
    runState.sortie += 1;
    beginSortie();
    return;
  }

  if (action === "equip") {
    const slot = button.dataset.slot as UpgradeSlot | undefined;
    const item = button.dataset.item;
    if (slot && item) {
      handleEquip(slot, item);
    }
    return;
  }

  if (action === "upgrade-front") {
    handleWeaponUpgrade("front");
    return;
  }

  if (action === "upgrade-rear") {
    handleWeaponUpgrade("rear");
  }
});

function tick(now: number): void {
  const frameDelta = Math.min(0.05, (now - lastFrame) / 1000);
  lastFrame = now;
  accumulator += frameDelta;

  while (accumulator >= fixedStep) {
    accumulator -= fixedStep;

    if (screen === "stage" && simulation) {
      const outcome = simulation.update(fixedStep, input);
      if (outcome) {
        completeSortie(outcome);
        break;
      }
    }
  }

  if (simulation) {
    renderer.render(simulation);
  } else {
    context.clearRect(0, 0, WORLD_WIDTH, WORLD_HEIGHT);
    context.fillStyle = "#08111a";
    context.fillRect(0, 0, WORLD_WIDTH, WORLD_HEIGHT);
  }

  renderHud();
  requestAnimationFrame(tick);
}

renderBriefing();
renderHud();
requestAnimationFrame(tick);

void slotLabel;
