import {
  enemyIndex,
  frontWeaponIndex,
  generatorIndex,
  rearWeaponIndex,
  shieldIndex,
  sidekickIndex,
} from "./data";
import type {
  CreditPickupState,
  EffectState,
  EnemyState,
  PlayerState,
  ProjectileState,
  RunState,
  SidekickArchetype,
  StageDefinition,
  StageOutcome,
  WaveCursor,
  WeaponArchetype,
  WeaponFireMode,
} from "./types";
import { InputState } from "./input";

export const WORLD_WIDTH = 360;
export const WORLD_HEIGHT = 640;

const PLAYER_SPEED = 228;
const PLAYER_ACCEL = 1220;
const PLAYER_FRICTION = 1450;

let nextEntityId = 1;

function approach(current: number, target: number, maxDelta: number): number {
  if (current < target) {
    return Math.min(target, current + maxDelta);
  }

  return Math.max(target, current - maxDelta);
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function distanceSquared(ax: number, ay: number, bx: number, by: number): number {
  const dx = ax - bx;
  const dy = ay - by;
  return dx * dx + dy * dy;
}

function weaponModeForRear(weapon: WeaponArchetype, modeIndex: 0 | 1): WeaponFireMode {
  if (modeIndex === 1 && weapon.modeB) {
    return weapon.modeB;
  }

  return weapon.modeA;
}

export class Simulation {
  readonly player: PlayerState;
  readonly projectiles: ProjectileState[] = [];
  readonly enemies: EnemyState[] = [];
  readonly credits: CreditPickupState[] = [];
  readonly effects: EffectState[] = [];

  private readonly waves: WaveCursor[];
  private readonly run: RunState;
  private readonly stage: StageDefinition;

  private elapsed = 0;
  private stageFinished = false;
  private bossSpawned = false;
  private frontWeapon: WeaponArchetype;
  private rearWeapon: WeaponArchetype;
  private leftSidekick: SidekickArchetype;
  private rightSidekick: SidekickArchetype;

  constructor(run: RunState, stage: StageDefinition) {
    this.run = run;
    this.stage = stage;
    this.waves = stage.spawns.map((stageSpawn) => ({ stageSpawn, spawned: 0 }));

    const shield = shieldIndex[run.loadout.shieldId];
    const generator = generatorIndex[run.loadout.generatorId];
    this.frontWeapon = frontWeaponIndex[run.loadout.frontWeaponId];
    this.rearWeapon = rearWeaponIndex[run.loadout.rearWeaponId];
    this.leftSidekick = sidekickIndex[run.loadout.leftSidekickId];
    this.rightSidekick = sidekickIndex[run.loadout.rightSidekickId];

    this.player = {
      x: WORLD_WIDTH / 2,
      y: WORLD_HEIGHT - 90,
      vx: 0,
      vy: 0,
      armor: 90,
      maxArmor: 90,
      shield: shield.maxShield,
      maxShield: shield.maxShield,
      shieldRegenPerSecond: shield.regenPerSecond,
      shieldRegenDelay: shield.regenDelay,
      shieldRegenCooldown: 0,
      energy: generator.maxEnergy,
      maxEnergy: generator.maxEnergy,
      energyRegenPerSecond: generator.regenPerSecond,
      frontCooldown: 0,
      rearCooldown: 0,
      leftSidekickCooldown: 0,
      rightSidekickCooldown: 0,
      invulnerability: 0,
      rearModeIndex: run.loadout.rearModeIndex,
    };
  }

  get stageTime(): number {
    return this.elapsed;
  }

  get sortie(): number {
    return this.run.sortie;
  }

  get loadout() {
    return this.run.loadout;
  }

  get rearModeLabel(): string {
    return weaponModeForRear(this.rearWeapon, this.player.rearModeIndex).label;
  }

  update(dt: number, input: InputState): StageOutcome | null {
    this.elapsed += dt;

    if (input.swapRearMode() && this.rearWeapon.modeB) {
      this.player.rearModeIndex = this.player.rearModeIndex === 0 ? 1 : 0;
      this.run.loadout.rearModeIndex = this.player.rearModeIndex;
      this.spawnEffect(this.player.x, this.player.y - 24, this.rearWeapon.color, "ring", 28, 0.32);
    }

    this.spawnWaves();
    this.updatePlayer(dt, input);
    this.updateEnemies(dt);
    this.updateProjectiles(dt);
    this.updateCredits(dt);
    this.updateEffects(dt);

    if (this.player.armor <= 0) {
      return {
        kind: "destroyed",
        earned: this.run.earnedThisSortie,
        totalCredits: this.run.credits,
        sortie: this.run.sortie,
      };
    }

    if (
      !this.stageFinished &&
      this.elapsed >= this.stage.duration &&
      this.enemies.length === 0 &&
      this.credits.length === 0 &&
      this.allWavesSpawned()
    ) {
      this.stageFinished = true;
      return {
        kind: "cleared",
        earned: this.run.earnedThisSortie,
        totalCredits: this.run.credits,
        sortie: this.run.sortie,
      };
    }

    return null;
  }

  private spawnWaves(): void {
    for (const wave of this.waves) {
      while (
        wave.spawned < wave.stageSpawn.count &&
        this.elapsed >= wave.stageSpawn.time + wave.stageSpawn.interval * wave.spawned
      ) {
        this.spawnEnemy(
          wave.stageSpawn.archetypeId,
          wave.stageSpawn.lane,
          wave.stageSpawn.variant ?? 0,
          wave.spawned,
          wave.stageSpawn.count,
        );
        wave.spawned += 1;
      }
    }
  }

  private allWavesSpawned(): boolean {
    return this.waves.every((wave) => wave.spawned >= wave.stageSpawn.count);
  }

  private spawnEnemy(archetypeId: string, lane: number, variant: number, order: number, count: number): void {
    const archetype = enemyIndex[archetypeId];
    const x = 56 + lane * 62 + (count > 1 ? (order - (count - 1) / 2) * 6 : 0);
    const y = archetype.behavior === "boss" ? -90 : -40 - order * 10;

    this.enemies.push({
      id: nextEntityId++,
      archetypeId,
      x,
      y,
      vx: 0,
      vy: archetype.speed,
      hp: this.scaledEnemyHp(archetype.hp),
      radius: archetype.radius,
      reward: this.scaledReward(archetype.reward),
      contactDamage: archetype.contactDamage,
      elapsed: 0,
      fireCooldown: archetype.fireCooldown * (0.7 + Math.random() * 0.5),
      variant,
    });

    if (archetype.behavior === "boss") {
      this.bossSpawned = true;
    }
  }

  private scaledEnemyHp(baseHp: number): number {
    return Math.round(baseHp * (1 + (this.run.sortie - 1) * 0.18));
  }

  private scaledReward(baseReward: number): number {
    return Math.round(baseReward * (1 + (this.run.sortie - 1) * 0.14));
  }

  private updatePlayer(dt: number, input: InputState): void {
    const axisX = input.axisX();
    const axisY = input.axisY();
    const targetVX = axisX * PLAYER_SPEED;
    const targetVY = axisY * PLAYER_SPEED;
    const accel = (axisX === 0 ? PLAYER_FRICTION : PLAYER_ACCEL) * dt;
    const accelY = (axisY === 0 ? PLAYER_FRICTION : PLAYER_ACCEL) * dt;

    this.player.vx = approach(this.player.vx, targetVX, accel);
    this.player.vy = approach(this.player.vy, targetVY, accelY);

    this.player.x = clamp(this.player.x + this.player.vx * dt, 24, WORLD_WIDTH - 24);
    this.player.y = clamp(this.player.y + this.player.vy * dt, 42, WORLD_HEIGHT - 32);

    this.player.frontCooldown = Math.max(0, this.player.frontCooldown - dt);
    this.player.rearCooldown = Math.max(0, this.player.rearCooldown - dt);
    this.player.leftSidekickCooldown = Math.max(0, this.player.leftSidekickCooldown - dt);
    this.player.rightSidekickCooldown = Math.max(0, this.player.rightSidekickCooldown - dt);
    this.player.invulnerability = Math.max(0, this.player.invulnerability - dt);

    this.player.energy = clamp(
      this.player.energy + this.player.energyRegenPerSecond * dt,
      0,
      this.player.maxEnergy,
    );

    if (this.player.shieldRegenCooldown > 0) {
      this.player.shieldRegenCooldown -= dt;
    } else {
      this.player.shield = clamp(
        this.player.shield + this.player.shieldRegenPerSecond * dt,
        0,
        this.player.maxShield,
      );
    }

    if (input.firing()) {
      this.fireFrontWeapon();
      this.fireRearWeapon();
    }

    if (input.leftSidekick()) {
      this.fireSidekick(this.leftSidekick, "left");
    }

    if (input.rightSidekick()) {
      this.fireSidekick(this.rightSidekick, "right");
    }
  }

  private fireFrontWeapon(): void {
    const powerScale = 1 + (this.run.loadout.frontPower - 1) * 0.18;
    if (this.player.frontCooldown > 0 || this.player.energy < this.frontWeapon.modeA.energyCost) {
      return;
    }

    this.player.energy -= this.frontWeapon.modeA.energyCost;
    this.player.frontCooldown = this.frontWeapon.modeA.cooldown / powerScale;
    this.emitPattern(
      "player",
      this.player.x,
      this.player.y - 16,
      this.frontWeapon.modeA,
      this.frontWeapon.color,
      -Math.PI / 2,
      powerScale,
      this.frontWeapon.frontArc ?? 0,
    );
  }

  private fireRearWeapon(): void {
    const mode = weaponModeForRear(this.rearWeapon, this.player.rearModeIndex);
    const powerScale = 1 + (this.run.loadout.rearPower - 1) * 0.16;
    if (this.player.rearCooldown > 0 || this.player.energy < mode.energyCost) {
      return;
    }

    this.player.energy -= mode.energyCost;
    this.player.rearCooldown = mode.cooldown / powerScale;
    const baseAngle = this.player.rearModeIndex === 0 ? Math.PI / 2 : Math.PI / 2;
    this.emitPattern(
      "player",
      this.player.x,
      this.player.y + 18,
      mode,
      this.rearWeapon.color,
      baseAngle,
      powerScale,
      mode.spread,
    );
  }

  private fireSidekick(sidekick: SidekickArchetype, lane: "left" | "right"): void {
    if (sidekick.id === "empty" || sidekick.energyCost <= 0) {
      return;
    }

    const cooldownKey = lane === "left" ? "leftSidekickCooldown" : "rightSidekickCooldown";
    if (this.player[cooldownKey] > 0 || this.player.energy < sidekick.energyCost) {
      return;
    }

    const orbitAngle = lane === "left" ? Math.PI * 0.9 : Math.PI * 0.1;
    const originX = this.player.x + Math.cos(this.elapsed * 3 + orbitAngle) * sidekick.orbitRadius;
    const originY = this.player.y + Math.sin(this.elapsed * 3 + orbitAngle) * 18;
    this.player.energy -= sidekick.energyCost;
    this.player[cooldownKey] = sidekick.cooldown;
    this.emitPattern(
      "player",
      originX,
      originY,
      {
        label: sidekick.name,
        cooldown: sidekick.cooldown,
        energyCost: sidekick.energyCost,
        damage: sidekick.damage,
        speed: sidekick.speed,
        spread: sidekick.spread,
        burst: sidekick.burst,
      },
      sidekick.color,
      -Math.PI / 2,
      1,
      sidekick.spread,
    );
  }

  private emitPattern(
    owner: "player" | "enemy",
    originX: number,
    originY: number,
    mode: WeaponFireMode,
    color: string,
    direction: number,
    powerScale: number,
    spreadOverride: number,
  ): void {
    const burst = Math.max(1, mode.burst);
    for (let index = 0; index < burst; index += 1) {
      const offset = burst === 1 ? 0 : index / (burst - 1) - 0.5;
      const angle = direction + offset * spreadOverride;
      const speed = mode.speed * (owner === "player" ? 1 : 0.92);
      this.projectiles.push({
        id: nextEntityId++,
        owner,
        x: originX,
        y: originY,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        damage: mode.damage * powerScale,
        radius: owner === "player" ? 5 : 6,
        color,
        life: owner === "player" ? 2.2 : 4,
      });
    }

    this.spawnEffect(originX, originY, color, "flash", 12, 0.14);
  }

  private updateEnemies(dt: number): void {
    for (const enemy of this.enemies) {
      const archetype = enemyIndex[enemy.archetypeId];
      enemy.elapsed += dt;
      enemy.fireCooldown -= dt;

      switch (archetype.behavior) {
        case "straight":
          enemy.y += archetype.speed * dt;
          break;
        case "sine":
          enemy.y += archetype.speed * dt;
          enemy.x += Math.sin(enemy.elapsed * 3.2 + enemy.variant) * 64 * dt;
          break;
        case "dive":
          enemy.y += archetype.speed * 0.72 * dt;
          enemy.x += Math.sin(enemy.elapsed * 4.1 + enemy.variant) * 120 * dt;
          if (enemy.elapsed > 1.25) {
            enemy.y += archetype.speed * 0.9 * dt;
          }
          break;
        case "boss":
          enemy.y = Math.min(114, enemy.y + archetype.speed * dt);
          enemy.x = WORLD_WIDTH / 2 + Math.sin(enemy.elapsed * 0.8) * 94;
          break;
      }

      if (enemy.fireCooldown <= 0) {
        this.fireEnemyWeapon(enemy, archetype);
        enemy.fireCooldown = archetype.fireCooldown;
      }

      if (distanceSquared(enemy.x, enemy.y, this.player.x, this.player.y) <= (enemy.radius + 14) ** 2) {
        this.damagePlayer(enemy.contactDamage);
        enemy.hp = 0;
      }
    }

    for (let index = this.enemies.length - 1; index >= 0; index -= 1) {
      const enemy = this.enemies[index];
      if (enemy.hp <= 0) {
        this.destroyEnemy(enemy);
        this.enemies.splice(index, 1);
        continue;
      }

      if (enemy.y > WORLD_HEIGHT + 70 || enemy.x < -80 || enemy.x > WORLD_WIDTH + 80) {
        this.enemies.splice(index, 1);
      }
    }
  }

  private fireEnemyWeapon(enemy: EnemyState, archetype: typeof enemyIndex[string]): void {
    if (archetype.firePattern === "none") {
      return;
    }

    if (archetype.firePattern === "aimed") {
      const angle = Math.atan2(this.player.y - enemy.y, this.player.x - enemy.x);
      this.emitPattern(
        "enemy",
        enemy.x,
        enemy.y + 10,
        {
          label: "Aimed",
          cooldown: archetype.fireCooldown,
          energyCost: 0,
          damage: 12 + this.run.sortie * 2,
          speed: archetype.projectileSpeed,
          spread: 0,
          burst: 1,
        },
        archetype.color,
        angle,
        1,
        0,
      );
      return;
    }

    if (archetype.firePattern === "spread") {
      this.emitPattern(
        "enemy",
        enemy.x,
        enemy.y + 12,
        {
          label: "Spread",
          cooldown: archetype.fireCooldown,
          energyCost: 0,
          damage: 10 + this.run.sortie * 2,
          speed: archetype.projectileSpeed,
          spread: 0.48,
          burst: 3,
        },
        archetype.color,
        Math.PI / 2,
        1,
        0.48,
      );
      return;
    }

    this.emitPattern(
      "enemy",
      enemy.x,
      enemy.y + 20,
      {
        label: "Boss Fan",
        cooldown: archetype.fireCooldown,
        energyCost: 0,
        damage: 13 + this.run.sortie * 2,
        speed: archetype.projectileSpeed,
        spread: 1.25,
        burst: enemy.elapsed % 4 < 2 ? 5 : 7,
      },
      archetype.color,
      Math.PI / 2,
      1,
      1.25,
    );
  }

  private updateProjectiles(dt: number): void {
    for (const projectile of this.projectiles) {
      projectile.x += projectile.vx * dt;
      projectile.y += projectile.vy * dt;
      projectile.life -= dt;
    }

    for (let index = this.projectiles.length - 1; index >= 0; index -= 1) {
      const projectile = this.projectiles[index];
      if (
        projectile.life <= 0 ||
        projectile.x < -40 ||
        projectile.x > WORLD_WIDTH + 40 ||
        projectile.y < -60 ||
        projectile.y > WORLD_HEIGHT + 60
      ) {
        this.projectiles.splice(index, 1);
        continue;
      }

      if (projectile.owner === "player") {
        const hitEnemy = this.enemies.find(
          (enemy) => distanceSquared(projectile.x, projectile.y, enemy.x, enemy.y) <= (projectile.radius + enemy.radius) ** 2,
        );
        if (hitEnemy) {
          hitEnemy.hp -= projectile.damage;
          this.spawnEffect(projectile.x, projectile.y, projectile.color, "burst", 14, 0.22);
          this.projectiles.splice(index, 1);
        }
      } else if (
        distanceSquared(projectile.x, projectile.y, this.player.x, this.player.y) <=
        (projectile.radius + 12) ** 2
      ) {
        this.damagePlayer(projectile.damage);
        this.spawnEffect(projectile.x, projectile.y, projectile.color, "flash", 16, 0.18);
        this.projectiles.splice(index, 1);
      }
    }
  }

  private damagePlayer(amount: number): void {
    if (this.player.invulnerability > 0) {
      return;
    }

    let damage = amount;
    if (this.player.shield > 0) {
      const absorbed = Math.min(this.player.shield, damage);
      this.player.shield -= absorbed;
      damage -= absorbed;
    }

    if (damage > 0) {
      this.player.armor = Math.max(0, this.player.armor - damage);
    }

    this.player.shieldRegenCooldown = this.player.shieldRegenDelay;
    this.player.invulnerability = 0.55;
    this.spawnEffect(this.player.x, this.player.y, "#ffffff", "ring", 26, 0.35);
  }

  private destroyEnemy(enemy: EnemyState): void {
    const isBoss = enemyIndex[enemy.archetypeId].behavior === "boss";
    const shards = isBoss ? 12 : Math.max(2, Math.round(enemy.reward / 16));
    const eachValue = Math.max(4, Math.round(enemy.reward / shards));

    for (let shard = 0; shard < shards; shard += 1) {
      const angle = (Math.PI * 2 * shard) / shards;
      this.credits.push({
        id: nextEntityId++,
        x: enemy.x,
        y: enemy.y,
        vx: Math.cos(angle) * (40 + Math.random() * 50),
        vy: Math.sin(angle) * (24 + Math.random() * 40),
        value: eachValue,
        radius: 7,
        age: 0,
      });
    }

    this.spawnEffect(enemy.x, enemy.y, enemyIndex[enemy.archetypeId].color, "burst", isBoss ? 50 : 24, isBoss ? 0.7 : 0.42);
    this.spawnEffect(enemy.x, enemy.y, "#ffffff", "ring", isBoss ? 78 : 28, isBoss ? 0.95 : 0.32);
  }

  private updateCredits(dt: number): void {
    for (const pickup of this.credits) {
      pickup.age += dt;
      pickup.vy += 40 * dt;

      const dx = this.player.x - pickup.x;
      const dy = this.player.y - pickup.y;
      const pull = clamp(420 / Math.max(1, Math.sqrt(dx * dx + dy * dy)), 0, 260);

      pickup.vx += (dx === 0 ? 0 : (dx / Math.abs(dx)) * pull) * dt;
      pickup.vy += (dy === 0 ? 0 : (dy / Math.abs(dy)) * pull) * dt;

      pickup.x += pickup.vx * dt;
      pickup.y += pickup.vy * dt;
    }

    for (let index = this.credits.length - 1; index >= 0; index -= 1) {
      const pickup = this.credits[index];
      if (distanceSquared(pickup.x, pickup.y, this.player.x, this.player.y) <= (pickup.radius + 14) ** 2) {
        this.run.credits += pickup.value;
        this.run.earnedThisSortie += pickup.value;
        this.spawnEffect(pickup.x, pickup.y, "#88ffd5", "flash", 14, 0.14);
        this.credits.splice(index, 1);
        continue;
      }

      if (pickup.age > 6 || pickup.y > WORLD_HEIGHT + 30) {
        this.credits.splice(index, 1);
      }
    }
  }

  private updateEffects(dt: number): void {
    for (let index = this.effects.length - 1; index >= 0; index -= 1) {
      this.effects[index].life -= dt;
      if (this.effects[index].life <= 0) {
        this.effects.splice(index, 1);
      }
    }
  }

  private spawnEffect(
    x: number,
    y: number,
    color: string,
    kind: EffectState["kind"],
    radius: number,
    life: number,
  ): void {
    this.effects.push({
      id: nextEntityId++,
      kind,
      x,
      y,
      color,
      radius,
      life,
      maxLife: life,
    });
  }

  getSidekickPosition(lane: "left" | "right"): { x: number; y: number } {
    const sidekick = lane === "left" ? this.leftSidekick : this.rightSidekick;
    const phase = lane === "left" ? Math.PI * 0.9 : Math.PI * 0.1;
    return {
      x: this.player.x + Math.cos(this.elapsed * 3 + phase) * sidekick.orbitRadius,
      y: this.player.y + Math.sin(this.elapsed * 3 + phase) * 18,
    };
  }

  getFrontWeapon(): WeaponArchetype {
    return this.frontWeapon;
  }

  getRearWeapon(): WeaponArchetype {
    return this.rearWeapon;
  }

  getSidekick(lane: "left" | "right"): SidekickArchetype {
    return lane === "left" ? this.leftSidekick : this.rightSidekick;
  }

  getBossActive(): boolean {
    return this.bossSpawned && this.enemies.some((enemy) => enemyIndex[enemy.archetypeId].behavior === "boss");
  }
}
