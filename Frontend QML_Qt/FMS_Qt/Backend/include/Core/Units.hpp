#pragma once

#include <cmath>

/**
 * Core/Units.hpp — type-safe physical units (Phase 1, IMPLEMENTATION_PLAN §3).
 *
 * Strong wrappers prevent unit mix-ups (feet vs metres vs radians) in new
 * backend code. Legacy code keeps raw doubles; new modules take/return these
 * and unwrap with .value() at the QML property boundary.
 *
 * Zero-overhead: constexpr, trivially copyable, no virtuals, no allocation.
 */
namespace Units {

template <typename Tag>
struct Quantity {
    double v{0.0};

    constexpr Quantity() = default;
    constexpr explicit Quantity(double value) : v(value) {}

    constexpr double value() const { return v; }

    constexpr Quantity operator+(Quantity o) const { return Quantity{v + o.v}; }
    constexpr Quantity operator-(Quantity o) const { return Quantity{v - o.v}; }
    constexpr Quantity operator-() const           { return Quantity{-v}; }
    constexpr Quantity operator*(double s) const   { return Quantity{v * s}; }
    constexpr Quantity operator/(double s) const   { return Quantity{v / s}; }
    constexpr double   operator/(Quantity o) const { return v / o.v; }  // ratio

    constexpr Quantity &operator+=(Quantity o) { v += o.v; return *this; }
    constexpr Quantity &operator-=(Quantity o) { v -= o.v; return *this; }

    constexpr auto operator<=>(const Quantity &) const = default;
};

// ── Length ───────────────────────────────────────────────────────────────────
struct FeetTag;          using Feet          = Quantity<FeetTag>;
struct MetersTag;        using Meters        = Quantity<MetersTag>;
struct NauticalMilesTag; using NauticalMiles = Quantity<NauticalMilesTag>;

// ── Speed ────────────────────────────────────────────────────────────────────
struct KnotsTag;          using Knots          = Quantity<KnotsTag>;
struct MetersPerSecTag;   using MetersPerSec   = Quantity<MetersPerSecTag>;
struct FeetPerMinuteTag;  using FeetPerMinute  = Quantity<FeetPerMinuteTag>;

// ── Angle ────────────────────────────────────────────────────────────────────
struct DegreesTag; using Degrees = Quantity<DegreesTag>;
struct RadiansTag; using Radians = Quantity<RadiansTag>;

// ── Mass / Force / Temperature ───────────────────────────────────────────────
struct KilogramsTag; using Kilograms = Quantity<KilogramsTag>;
struct NewtonsTag;   using Newtons   = Quantity<NewtonsTag>;
struct CelsiusTag;   using Celsius   = Quantity<CelsiusTag>;
struct KelvinTag;    using Kelvin    = Quantity<KelvinTag>;

// ── Conversion constants ─────────────────────────────────────────────────────
inline constexpr double kFtPerM   = 3.280839895;
inline constexpr double kMPerFt   = 0.3048;
inline constexpr double kMsPerKt  = 0.514444;
inline constexpr double kMPerNm   = 1852.0;
inline constexpr double kPi       = 3.14159265358979323846;

// ── Conversions ──────────────────────────────────────────────────────────────
constexpr Meters toMeters(Feet f)            { return Meters{f.value() * kMPerFt}; }
constexpr Feet   toFeet(Meters m)            { return Feet{m.value() * kFtPerM}; }
constexpr MetersPerSec toMetersPerSec(Knots k) { return MetersPerSec{k.value() * kMsPerKt}; }
constexpr Knots  toKnots(MetersPerSec ms)    { return Knots{ms.value() / kMsPerKt}; }
constexpr Radians toRadians(Degrees d)       { return Radians{d.value() * kPi / 180.0}; }
constexpr Degrees toDegrees(Radians r)       { return Degrees{r.value() * 180.0 / kPi}; }
constexpr Kelvin  toKelvin(Celsius c)        { return Kelvin{c.value() + 273.15}; }
constexpr Celsius toCelsius(Kelvin k)        { return Celsius{k.value() - 273.15}; }

// User-defined literals for readable constants: 350.0_kt, 32000.0_ft, ...
namespace Literals {
constexpr Feet      operator""_ft(long double v)  { return Feet{static_cast<double>(v)}; }
constexpr Knots     operator""_kt(long double v)  { return Knots{static_cast<double>(v)}; }
constexpr Degrees   operator""_deg(long double v) { return Degrees{static_cast<double>(v)}; }
constexpr Kilograms operator""_kg(long double v)  { return Kilograms{static_cast<double>(v)}; }
constexpr Newtons   operator""_N(long double v)   { return Newtons{static_cast<double>(v)}; }
} // namespace Literals

} // namespace Units
