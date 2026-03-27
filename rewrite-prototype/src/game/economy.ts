import type { UpgradeCatalog, UpgradeSlot } from "./types";

export function triangular(step: number): number {
  return (step * (step + 1)) / 2;
}

export function nextWeaponUpgradeCost(basePrice: number, currentPower: number): number {
  return basePrice * triangular(currentPower);
}

export function maxWeaponPower(): number {
  return 5;
}

export function slotLabel(slot: UpgradeSlot): string {
  switch (slot) {
    case "front":
      return "Front Weapon";
    case "rear":
      return "Rear Weapon";
    case "shield":
      return "Shield";
    case "generator":
      return "Generator";
    case "leftSidekick":
      return "Left Sidekick";
    case "rightSidekick":
      return "Right Sidekick";
  }
}

export function getCatalogItemBasePrice(
  catalog: UpgradeCatalog,
  slot: UpgradeSlot,
  itemId: string,
): number {
  switch (slot) {
    case "front":
      return catalog.frontWeapons.find((item) => item.id === itemId)?.basePrice ?? 0;
    case "rear":
      return catalog.rearWeapons.find((item) => item.id === itemId)?.basePrice ?? 0;
    case "shield":
      return catalog.shields.find((item) => item.id === itemId)?.basePrice ?? 0;
    case "generator":
      return catalog.generators.find((item) => item.id === itemId)?.basePrice ?? 0;
    case "leftSidekick":
    case "rightSidekick":
      return catalog.sidekicks.find((item) => item.id === itemId)?.basePrice ?? 0;
  }
}
