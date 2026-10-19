//! Colors for a small terminal renderer.

use std::collections::HashMap;
use std::fmt;

/// A 24-bit color, parsed from `#rrggbb`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Rgb(pub u8, pub u8, pub u8);

#[derive(Debug)]
pub enum ParseError {
    MissingHash,
    BadLength(usize),
    BadDigit { at: usize, found: char },
}

impl Rgb {
    pub const BLACK: Rgb = Rgb(0x00, 0x00, 0x00);

    pub fn parse(hex: &str) -> Result<Self, ParseError> {
        let digits = hex.strip_prefix('#').ok_or(ParseError::MissingHash)?;
        if digits.len() != 6 {
            return Err(ParseError::BadLength(digits.len()));
        }
        let channel = |i: usize| u8::from_str_radix(&digits[i..i + 2], 16);
        match (channel(0), channel(2), channel(4)) {
            (Ok(r), Ok(g), Ok(b)) => Ok(Rgb(r, g, b)),
            _ => Err(ParseError::BadDigit { at: 0, found: '?' }),
        }
    }

    /// Mix `self` over `base`; `alpha` is clamped to 0.0..=1.0.
    pub fn blend(self, alpha: f32, base: Rgb) -> Rgb {
        let a = alpha.clamp(0.0, 1.0);
        let mix = |fg: u8, bg: u8| (a * fg as f32 + (1.0 - a) * bg as f32).round() as u8;
        Rgb(mix(self.0, base.0), mix(self.1, base.1), mix(self.2, base.2))
    }
}

pub struct Palette<'a> {
    name: &'a str,
    colors: HashMap<&'a str, Rgb>,
}

impl<'a> Palette<'a> {
    pub fn night() -> Self {
        let colors = [("bg", "#1a1b26"), ("fg", "#c0caf5"), ("blue", "#7aa2f7")]
            .into_iter()
            .filter_map(|(k, v)| Rgb::parse(v).ok().map(|c| (k, c)))
            .collect();
        Palette { name: "night", colors }
    }
}

impl fmt::Display for Palette<'_> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        writeln!(f, "palette \"{}\" ({} colors)\n", self.name, self.colors.len())?;
        for (name, Rgb(r, g, b)) in &self.colors {
            writeln!(f, "  {name:<6} #{r:02x}{g:02x}{b:02x}")?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn blends_toward_base() {
        let half = Rgb(255, 255, 255).blend(0.5, Rgb::BLACK);
        assert_eq!(half, Rgb(128, 128, 128));
    }
}
