export type UpgradeSlot =
  | "front"
  | "rear"
  | "shield"
  | "generator"
  | "leftSidekick"
  | "rightSidekick";

export type SidekickFireLane = "left" | "right";
export type EnemyBehavior = "straight" | "sine" | "dive" | "boss";
export type EnemyFirePattern = "none" | "aimed" | "spread" | "boss";

export interface StageSpawn {
  time: number;
  archetypeId: string;
  lane: number;
  count: number;
  interval: number;
  variant?: number;
}

export interface StageDefinition {
  id: string;
  name: string;
  duration: number;
  spawns: StageSpawn[];
}

export interface EnemyArchetype {
  id: string;
  name: string;
  behavior: EnemyBehavior;
  firePattern: EnemyFirePattern;
  speed: number;
  hp: number;
  radius: number;
  reward: number;
  color: string;
  contactDamage: number;
  fireCooldown: number;
  projectileSpeed: number;
}

export interface WeaponFireMode {
  label: string;
  cooldown: number;
  energyCost: number;
  damage: number;
  speed: number;
  spread: number;
  burst: number;
}

export interface WeaponArchetype {
  id: string;
  name: string;
  slot: "front" | "rear";
  basePrice: number;
  color: string;
  modeA: WeaponFireMode;
  modeB?: WeaponFireMode;
  frontArc?: number;
}

export interface ShieldArchetype {
  id: string;
  name: string;
  basePrice: number;
  maxShield: number;
  regenPerSecond: number;
  regenDelay: number;
  color: string;
}

export interface GeneratorArchetype {
  id: string;
  name: string;
  basePrice: number;
  maxEnergy: number;
  regenPerSecond: number;
  color: string;
}

export interface SidekickArchetype {
  id: string;
  name: string;
  basePrice: number;
  color: string;
  fireLane: SidekickFireLane;
  cooldown: number;
  energyCost: number;
  damage: number;
  speed: number;
  spread: number;
  burst: number;
  orbitRadius: number;
}

export interface UpgradeCatalog {
  frontWeapons: WeaponArchetype[];
  rearWeapons: WeaponArchetype[];
  shields: ShieldArchetype[];
  generators: GeneratorArchetype[];
  sidekicks: SidekickArchetype[];
}

export interface PlayerLoadout {
  frontWeaponId: string;
  rearWeaponId: string;
  shieldId: string;
  generatorId: string;
  leftSidekickId: string;
  rightSidekickId: string;
  frontPower: number;
  rearPower: number;
  rearModeIndex: 0 | 1;
}

export interface RunState {
  sortie: number;
  credits: number;
  earnedThisSortie: number;
  loadout: PlayerLoadout;
}

export interface PlayerState {
  x: number;
  y: number;
  vx: number;
  vy: number;
  armor: number;
  maxArmor: number;
  shield: number;
  maxShield: number;
  shieldRegenPerSecond: number;
  shieldRegenDelay: number;
  shieldRegenCooldown: number;
  energy: number;
  maxEnergy: number;
  energyRegenPerSecond: number;
  frontCooldown: number;
  rearCooldown: number;
  leftSidekickCooldown: number;
  rightSidekickCooldown: number;
  invulnerability: number;
  rearModeIndex: 0 | 1;
}

export interface EnemyState {
  id: number;
  archetypeId: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
  hp: number;
  radius: number;
  reward: number;
  contactDamage: number;
  elapsed: number;
  fireCooldown: number;
  variant: number;
}

export interface ProjectileState {
  id: number;
  owner: "player" | "enemy";
  x: number;
  y: number;
  vx: number;
  vy: number;
  damage: number;
  radius: number;
  color: string;
  life: number;
}

export interface CreditPickupState {
  id: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  value: number;
  radius: number;
  age: number;
}

export interface EffectState {
  id: number;
  kind: "burst" | "ring" | "flash";
  x: number;
  y: number;
  color: string;
  life: number;
  maxLife: number;
  radius: number;
}

export interface WaveCursor {
  stageSpawn: StageSpawn;
  spawned: number;
}

export interface StageOutcome {
  kind: "cleared" | "destroyed";
  earned: number;
  totalCredits: number;
  sortie: number;
}

export interface ShopSection<TItem> {
  title: string;
  slot: UpgradeSlot;
  currentId: string;
  items: readonly TItem[];
}
