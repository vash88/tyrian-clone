export class InputState {
  private readonly pressed = new Set<string>();
  private readonly consumed = new Set<string>();

  constructor() {
    window.addEventListener("keydown", (event) => {
      if (
        event.code === "ArrowUp" ||
        event.code === "ArrowDown" ||
        event.code === "ArrowLeft" ||
        event.code === "ArrowRight" ||
        event.code === "Space" ||
        event.code === "Enter" ||
        event.code.startsWith("Control") ||
        event.code.startsWith("Alt")
      ) {
        event.preventDefault();
      }

      this.pressed.add(event.code);
    });

    window.addEventListener("keyup", (event) => {
      this.pressed.delete(event.code);
      this.consumed.delete(event.code);
    });

    window.addEventListener("blur", () => {
      this.pressed.clear();
      this.consumed.clear();
    });
  }

  isDown(code: string): boolean {
    return this.pressed.has(code);
  }

  pressedOnce(code: string): boolean {
    if (!this.pressed.has(code) || this.consumed.has(code)) {
      return false;
    }

    this.consumed.add(code);
    return true;
  }

  axisX(): number {
    return (this.isDown("ArrowRight") ? 1 : 0) - (this.isDown("ArrowLeft") ? 1 : 0);
  }

  axisY(): number {
    return (this.isDown("ArrowDown") ? 1 : 0) - (this.isDown("ArrowUp") ? 1 : 0);
  }

  firing(): boolean {
    return this.isDown("Space");
  }

  leftSidekick(): boolean {
    return this.isDown("ControlLeft") || this.isDown("ControlRight");
  }

  rightSidekick(): boolean {
    return this.isDown("AltLeft") || this.isDown("AltRight");
  }

  swapRearMode(): boolean {
    return this.pressedOnce("Enter");
  }
}
