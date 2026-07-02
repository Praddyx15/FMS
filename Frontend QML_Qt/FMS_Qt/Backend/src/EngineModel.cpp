#include "EngineModel.hpp"

#include <algorithm>

void EngineModel::tick(double dt, bool fire1, bool fire2)
{
    // Fire: thrust decays and N1 follows it directly (windmilling spool-down).
    if (fire1) {
        thrust1 = std::max(0.0, thrust1 - dt * kFireDecayPerSec);
        n1Left  = thrust1 * 2.0;
    }
    if (fire2) {
        thrust2 = std::max(0.0, thrust2 - dt * kFireDecayPerSec);
        n1Right = thrust2 * 2.0;
    }

    // Legacy behaviour preserved: any active engine fire inhibits the normal
    // spool/EGT update for both engines (Phase 3 models engines independently).
    if (fire1 || fire2)
        return;

    // First-order N1 lag toward the lever-commanded target
    const double n1Target1 = thrust1 * kN1PerThrust;
    const double n1Target2 = thrust2 * kN1PerThrust;
    n1Left  += (n1Target1 - n1Left)  * dt * kN1LagPerSec;
    n1Right += (n1Target2 - n1Right) * dt * kN1LagPerSec;
    n1Left  = std::clamp(n1Left,  0.0, kN1Max);
    n1Right = std::clamp(n1Right, 0.0, kN1Max);

    // EGT (simplified linear map; Phase 3: lookup vs N1/alt/Mach + thermal lag)
    egtLeft  = kEgtBase + n1Left  * kEgtPerN1;
    egtRight = kEgtBase + n1Right * kEgtPerN1;
}
