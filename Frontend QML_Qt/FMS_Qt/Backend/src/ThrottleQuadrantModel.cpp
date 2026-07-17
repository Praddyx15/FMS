#include "ThrottleQuadrantModel.hpp"

void ThrottleQuadrantModel::tick(double /*dt*/, bool onGround, bool athrRequested)
{
    // ── Ground-spoiler auto-deploy/retract ────────────────────────────────────
    // Real A320 behaviour: armed speedbrakes extend automatically at touchdown
    // (WoW) and retract automatically on a go-around (airborne again).
    if (onGround && !m_prevOnGround && speedbrakeArmed) {
        speedbrakeLever = 1.0;
    } else if (!onGround && m_prevOnGround) {
        speedbrakeLever = 0.0;
    }
    m_prevOnGround = onGround;

    // ── A/THR detent arbitration ──────────────────────────────────────────────
    // A/THR only manages thrust while the levers sit in the CL detent; above CL
    // (MCT/FLX or TOGA) the pilot has taken manual control. Below CL (IDLE) is
    // still A/THR-managed (idle/approach speed management).
    Detent d1 = getDetent(tla1);
    Detent d2 = getDetent(tla2);
    athrManualOverrideActive = athrRequested &&
        (d1 == MCT_FLX || d1 == TOGA || d2 == MCT_FLX || d2 == TOGA);

    // ── Reverse-thrust ground interlock ───────────────────────────────────────
    reverseInterlockTripped = !onGround && (d1 == REVERSE || d2 == REVERSE);
}
