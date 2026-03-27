import {
  enemyIndex,
  frontWeaponIndex,
  rearWeaponIndex,
  shieldIndex,
  sidekickIndex,
} from "./data";
import { WORLD_HEIGHT, WORLD_WIDTH, type Simulation } from "./simulation";

const bgGrid = 24;

function alpha(hex: string, opacity: number): string {
  const normalized = hex.replace("#", "");
  if (normalized.length !== 6) {
    return hex;
  }

  const channel = Math.round(opacity * 255)
    .toString(16)
    .padStart(2, "0");
  return `#${normalized}${channel}`;
}

export class Renderer {
  constructor(canvas: HTMLCanvasElement, private readonly context: CanvasRenderingContext2D) {
    canvas.width = WORLD_WIDTH;
    canvas.height = WORLD_HEIGHT;
  }

  render(simulation: Simulation): void {
    const ctx = this.context;
    ctx.clearRect(0, 0, WORLD_WIDTH, WORLD_HEIGHT);
    this.drawBackground(ctx, simulation.stageTime);
    this.drawStageFrame(ctx);
    this.drawCredits(ctx, simulation);
    this.drawProjectiles(ctx, simulation);
    this.drawEnemies(ctx, simulation);
    this.drawSidekicks(ctx, simulation);
    this.drawPlayer(ctx, simulation);
    this.drawEffects(ctx, simulation);
    this.drawBossLine(ctx, simulation);
  }

  private drawBackground(ctx: CanvasRenderingContext2D, stageTime: number): void {
    const gradient = ctx.createLinearGradient(0, 0, 0, WORLD_HEIGHT);
    gradient.addColorStop(0, "#09131c");
    gradient.addColorStop(1, "#02060c");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, WORLD_WIDTH, WORLD_HEIGHT);

    ctx.save();
    ctx.translate(0, (stageTime * 60) % bgGrid);
    ctx.strokeStyle = alpha("#2a4a68", 0.42);
    ctx.lineWidth = 1;
    for (let y = -bgGrid; y < WORLD_HEIGHT + bgGrid; y += bgGrid) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(WORLD_WIDTH, y);
      ctx.stroke();
    }
    for (let x = 12; x < WORLD_WIDTH; x += bgGrid) {
      ctx.beginPath();
      ctx.moveTo(x, -bgGrid);
      ctx.lineTo(x, WORLD_HEIGHT + bgGrid);
      ctx.stroke();
    }
    ctx.restore();
  }

  private drawStageFrame(ctx: CanvasRenderingContext2D): void {
    ctx.strokeStyle = alpha("#98c4f7", 0.18);
    ctx.lineWidth = 2;
    ctx.strokeRect(6, 6, WORLD_WIDTH - 12, WORLD_HEIGHT - 12);
  }

  private drawPlayer(ctx: CanvasRenderingContext2D, simulation: Simulation): void {
    const player = simulation.player;
    const front = frontWeaponIndex[simulation.loadout.frontWeaponId];
    const shield = shieldIndex[simulation.loadout.shieldId];

    ctx.save();
    ctx.translate(player.x, player.y);
    ctx.strokeStyle = front.color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(0, -16);
    ctx.lineTo(13, 14);
    ctx.lineTo(0, 8);
    ctx.lineTo(-13, 14);
    ctx.closePath();
    ctx.stroke();

    ctx.strokeStyle = alpha(shield.color, player.shield > 1 ? 0.7 : 0.16);
    ctx.beginPath();
    ctx.arc(0, 0, 22, 0, Math.PI * 2);
    ctx.stroke();

    if (player.invulnerability > 0) {
      ctx.strokeStyle = alpha("#ffffff", 0.5 + Math.sin(player.invulnerability * 24) * 0.2);
      ctx.beginPath();
      ctx.arc(0, 0, 28, 0, Math.PI * 2);
      ctx.stroke();
    }

    ctx.restore();
  }

  private drawSidekicks(ctx: CanvasRenderingContext2D, simulation: Simulation): void {
    for (const lane of ["left", "right"] as const) {
      const sidekick = sidekickIndex[lane === "left" ? simulation.loadout.leftSidekickId : simulation.loadout.rightSidekickId];
      if (sidekick.id === "empty") {
        continue;
      }

      const { x, y } = simulation.getSidekickPosition(lane);
      ctx.save();
      ctx.translate(x, y);
      ctx.strokeStyle = sidekick.color;
      ctx.lineWidth = 1.75;
      ctx.beginPath();
      ctx.rect(-8, -8, 16, 16);
      ctx.stroke();
      ctx.restore();
    }
  }

  private drawEnemies(ctx: CanvasRenderingContext2D, simulation: Simulation): void {
    for (const enemy of simulation.enemies) {
      const archetype = enemyIndex[enemy.archetypeId];
      ctx.save();
      ctx.translate(enemy.x, enemy.y);
      ctx.strokeStyle = archetype.color;
      ctx.lineWidth = archetype.behavior === "boss" ? 3 : 2;

      if (archetype.behavior === "boss") {
        ctx.beginPath();
        ctx.moveTo(-36, 0);
        ctx.lineTo(-10, -26);
        ctx.lineTo(10, -26);
        ctx.lineTo(36, 0);
        ctx.lineTo(18, 30);
        ctx.lineTo(-18, 30);
        ctx.closePath();
        ctx.stroke();
      } else {
        ctx.beginPath();
        ctx.moveTo(0, -enemy.radius);
        ctx.lineTo(enemy.radius, 0);
        ctx.lineTo(0, enemy.radius);
        ctx.lineTo(-enemy.radius, 0);
        ctx.closePath();
        ctx.stroke();
      }

      ctx.restore();
    }
  }

  private drawProjectiles(ctx: CanvasRenderingContext2D, simulation: Simulation): void {
    for (const projectile of simulation.projectiles) {
      ctx.save();
      ctx.strokeStyle = projectile.color;
      ctx.fillStyle = projectile.color;
      ctx.lineWidth = projectile.owner === "player" ? 2 : 1.5;
      ctx.beginPath();
      ctx.arc(projectile.x, projectile.y, projectile.radius, 0, Math.PI * 2);
      if (projectile.owner === "player") {
        ctx.stroke();
      } else {
        ctx.fill();
      }
      ctx.restore();
    }
  }

  private drawCredits(ctx: CanvasRenderingContext2D, simulation: Simulation): void {
    for (const pickup of simulation.credits) {
      ctx.save();
      ctx.translate(pickup.x, pickup.y);
      ctx.strokeStyle = "#88ffd5";
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(0, -7);
      ctx.lineTo(6, -3);
      ctx.lineTo(6, 3);
      ctx.lineTo(0, 7);
      ctx.lineTo(-6, 3);
      ctx.lineTo(-6, -3);
      ctx.closePath();
      ctx.stroke();
      ctx.restore();
    }
  }

  private drawEffects(ctx: CanvasRenderingContext2D, simulation: Simulation): void {
    for (const effect of simulation.effects) {
      const life = effect.life / effect.maxLife;
      ctx.save();
      ctx.strokeStyle = alpha(effect.color, life);
      ctx.fillStyle = alpha(effect.color, life);
      ctx.lineWidth = 2;
      if (effect.kind === "flash") {
        ctx.beginPath();
        ctx.arc(effect.x, effect.y, effect.radius * (1 - life * 0.45), 0, Math.PI * 2);
        ctx.fill();
      } else {
        ctx.beginPath();
        ctx.arc(effect.x, effect.y, effect.radius * (1 - life) + 6, 0, Math.PI * 2);
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  private drawBossLine(ctx: CanvasRenderingContext2D, simulation: Simulation): void {
    if (!simulation.getBossActive()) {
      return;
    }

    const rear = rearWeaponIndex[simulation.loadout.rearWeaponId];
    ctx.save();
    ctx.strokeStyle = alpha(rear.color, 0.18);
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(24, 112);
    ctx.lineTo(WORLD_WIDTH - 24, 112);
    ctx.stroke();
    ctx.restore();
  }
}
