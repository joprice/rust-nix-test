fn main() -> Result<(), Box<dyn std::error::Error>> {
    let out = std::env::var("PROTOS_DIR")?;
    let protos = std::path::Path::new(&out);
    let proto = protos.join("registry.proto");
    tonic_build::configure()
        .build_server(false)
        .compile(&[proto], &[protos.to_path_buf()])?;
    Ok(())
}
