// AES Formal — Rust entry point
pub mod gf256;
pub mod sbox;
pub mod linear_layer;
pub mod reductions;
pub mod aes128;
pub mod complexity;
pub mod cross_verification;

fn main() {
    println!("AES Formal Verification — Rust");
    println!("FIPS-197 test vector: {}", aes128::verify_fips197());
    println!("No break: {}", complexity::verify_no_break());
}
