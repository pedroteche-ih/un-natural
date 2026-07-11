// Engine_UnNatural.sc -- simple one-shot AR sine voice for un-natural.
// Each `trig` spawns a self-freeing synth, so chords = several trigs.
// After adding/editing this file, run `;restart` in maiden to recompile.

Engine_UnNatural : CroneEngine {

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    SynthDef(\un_sine, { |out, freq = 220, atk = 0.01, rel = 0.5, amp = 0.2|
      var env = EnvGen.kr(Env.perc(atk, rel, 1, -4), doneAction: 2);
      Out.ar(out, (SinOsc.ar(freq) * env * amp).dup);
    }).add;

    context.server.sync; // wait until the SynthDef is available

    // engine.trig(freq, atk, rel, amp) -- one-shot AR sine note
    this.addCommand("trig", "ffff", { |msg|
      Synth.new(\un_sine, [
        \out, context.out_b,
        \freq, msg[1], \atk, msg[2], \rel, msg[3], \amp, msg[4]
      ], context.xg);
    });
  }

  free {}
}
