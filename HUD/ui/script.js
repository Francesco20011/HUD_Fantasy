window.addEventListener('DOMContentLoaded', () => {
  fetch(`https://${GetParentResourceName()}/loaded`, {
    method: 'POST',
    body: '{}'
  });
});

window.addEventListener('message', (event) => {
  if (event.data.type === 'toggle') {
    document.body.style.display = event.data.status ? 'block' : 'none';
  }

  if (event.data.type === 'cinema') {
    const cinemaOverlay = document.getElementById('cinema-overlay');
    const hudFantasy = document.getElementById('hud-fantasy');
    const serverLogo = document.getElementById('server-logo');
    if (cinemaOverlay) {
      cinemaOverlay.style.display = event.data.status ? 'flex' : 'none';
      if (hudFantasy) hudFantasy.style.display = event.data.status ? 'none' : 'flex';
      if (serverLogo) serverLogo.style.display = event.data.status ? 'none' : 'flex';
    }
  }

  if (event.data.type === 'update') {
    // ======= PATCH: Mostra la vita reale come "curHealth/maxHealth" =======
    if (typeof event.data.curHealth !== "undefined" && typeof event.data.maxHealth !== "undefined") {
      document.getElementById('hpbar-text').textContent = `${event.data.curHealth}/${event.data.maxHealth}`;
    } else {
      document.getElementById('hpbar-text').textContent = event.data.health;
    }
    document.getElementById('hpbar-inner').style.width = event.data.health + '%';

    document.getElementById('armorbar-text').textContent = event.data.armor;
    document.getElementById('armorbar-inner').style.width = event.data.armor + '%';

    document.getElementById('hunger-value').textContent = event.data.hunger;
    document.getElementById('icon-hunger').style.setProperty('--percent', event.data.hunger);

    document.getElementById('thirst-value').textContent = event.data.thirst;
    document.getElementById('icon-thirst').style.setProperty('--percent', event.data.thirst);

    document.getElementById('stamina-value').textContent = event.data.stamina;
    document.getElementById('icon-stamina').style.setProperty('--percent', event.data.stamina);

    document.getElementById('stress-value').textContent = event.data.stress;
    document.getElementById('icon-stress').style.setProperty('--percent', event.data.stress);

    document.getElementById('id-value').textContent = event.data.id;
  }

  // MIC MODE + STATO
  if (event.data.type === "mic") {
    setMicState(event.data.talking, event.data.voicemode ?? 1);
  }
});

function setMicState(isTalking, voicemode) {
  const micIcon = document.getElementById('icon-mic');
  if (!micIcon) return;
  micIcon.classList.remove('mic-whisper', 'mic-normal', 'mic-shout', 'icon-mic-active', 'icon-mic-inactive');
  if (isTalking) {
    if (voicemode === 0) micIcon.classList.add('mic-whisper');
    else if (voicemode === 2) micIcon.classList.add('mic-shout');
    else micIcon.classList.add('mic-normal');
  } else {
    micIcon.classList.add('icon-mic-inactive');
  }
}
