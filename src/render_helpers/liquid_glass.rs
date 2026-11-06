use niri_config::LiquidGlass;
use smithay::backend::renderer::gles::{Uniform, UniformName, UniformType};

/// Shader uniform names, in the same order as the values in `uniforms()`.
const NAMES: [&str; 18] = [
    "lg_refraction_strength",
    "lg_power_factor",
    "lg_refraction_power",
    "lg_physical_refraction",
    "lg_glow_weight",
    "lg_edge_lighting",
    "lg_fringing",
    "lg_refraction_dilute",
    "lg_dilute_strength",
    "lg_dilute_fringing",
    "lg_lens_distortion",
    "lg_brightness",
    "lg_contrast",
    "lg_saturation",
    "lg_vibrancy",
    "lg_adaptive_dim",
    "lg_adaptive_boost",
    "lg_edge_thickness",
];

pub fn uniform_names() -> impl Iterator<Item = UniformName<'static>> {
    NAMES
        .into_iter()
        .map(|name| UniformName::new(name, UniformType::_1f))
}

pub fn uniforms(lg: Option<&LiquidGlass>) -> Vec<Uniform<'static>> {
    // The shader skips the whole effect when strength is 0, so the rest can stay unset.
    let Some(lg) = lg else {
        return vec![Uniform::new("lg_refraction_strength", 0f32)];
    };

    // Typed length makes the compiler catch a value without a name (or the reverse).
    let values: [f64; NAMES.len()] = [
        lg.refraction_strength,
        lg.power_factor,
        lg.refraction_power,
        lg.physical_refraction,
        lg.glow_weight,
        lg.edge_lighting,
        lg.fringing,
        lg.refraction_dilute,
        lg.dilute_strength,
        lg.dilute_fringing,
        lg.lens_distortion,
        lg.brightness,
        lg.contrast,
        lg.saturation,
        lg.vibrancy,
        lg.adaptive_dim,
        lg.adaptive_boost,
        lg.edge_thickness,
    ];

    NAMES
        .into_iter()
        .zip(values)
        .map(|(name, value)| Uniform::new(name, value as f32))
        .collect()
}
