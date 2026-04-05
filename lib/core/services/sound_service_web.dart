// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playReminderSound() {
  try {
    js.context.callMethod('eval', ['''
      (function() {
        var AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (!AudioCtx) return;
        var ctx = new AudioCtx();
        function beep(freq, start, end) {
          var osc  = ctx.createOscillator();
          var gain = ctx.createGain();
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.type = 'sine';
          osc.frequency.value = freq;
          gain.gain.value = 0.22;
          osc.start(ctx.currentTime + start);
          osc.stop(ctx.currentTime + end);
        }
        beep(880,  0.00, 0.12);
        beep(1047, 0.18, 0.30);
        beep(1319, 0.36, 0.55);
      })();
    ''']);
  } catch (_) {}
}
