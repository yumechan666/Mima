const NOTES = {
  jump: [392, 0.08, "triangle", 0.045],
  leaf: [784, 0.11, "sine", 0.07],
  clue: [523, 0.18, "triangle", 0.08],
  action: [330, 0.09, "triangle", 0.045],
  echo: [196, 0.32, "sine", 0.09],
  hit: [110, 0.12, "sawtooth", 0.055],
  slam: [82, 0.16, "triangle", 0.09],
  success: [659, 0.28, "sine", 0.075],
};

export function createAudio({ sdk, shell }) {
  let managed = null;
  let ready = false;
  let disposed = false;

  const managedPromise = sdk.audio.getContext().then((value) => {
    managed = value;
    return value;
  }).catch(() => null);

  async function unlock() {
    const value = await managedPromise;
    if (!value || disposed) return;
    try {
      await value.unlock();
      ready = value.context.state === "running";
      if (ready) {
        shell.removeEventListener("pointerdown", unlock, true);
        shell.removeEventListener("keydown", unlock, true);
      }
    } catch {
      // Audio is optional; play continues silently when the host blocks it.
    }
  }

  shell.addEventListener("pointerdown", unlock, true);
  shell.addEventListener("keydown", unlock, true);

  function tone(frequency, duration, type, volume, delay = 0) {
    if (!ready || !managed || managed.context.state !== "running") return;
    const context = managed.context;
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    const start = context.currentTime + delay;
    oscillator.type = type;
    oscillator.frequency.setValueAtTime(frequency, start);
    gain.gain.setValueAtTime(volume, start);
    gain.gain.exponentialRampToValueAtTime(0.001, start + duration);
    oscillator.connect(gain).connect(context.destination);
    oscillator.start(start);
    oscillator.stop(start + duration);
  }

  return {
    play(name) {
      const note = NOTES[name];
      if (!note) return;
      tone(...note);
      if (name === "leaf") tone(note[0] * 1.25, note[1], note[2], note[3] * 0.7, 0.055);
      if (name === "success") tone(note[0] * 1.5, note[1], note[2], note[3] * 0.75, 0.12);
      if (name === "echo") tone(293.7, 0.38, "sine", 0.04, 0.09);
    },
    async destroy() {
      disposed = true;
      shell.removeEventListener("pointerdown", unlock, true);
      shell.removeEventListener("keydown", unlock, true);
      if (managed) await managed.dispose().catch(() => {});
    },
  };
}
