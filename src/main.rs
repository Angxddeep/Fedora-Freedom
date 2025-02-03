use std::process::{Command, Stdio};
use std::io;
use dialoguer::{Select, Confirm};
use colored::*;

// Color-coded output
fn color_echo(color: &str, text: &str) {
    match color {
        "red" => println!("{}", text.red()),
        "green" => println!("{}", text.green()),
        "yellow" => println!("{}", text.yellow()),
        "blue" => println!("{}", text.blue()),
        _ => println!("{}", text),
    }
}

fn add_flathub() {
    color_echo("yellow", "Adding Flathub...");
    let status = Command::new("flatpak")
        .args(&["remote-add", "--if-not-exists", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"])
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .expect("Failed to add Flathub");

    if status.success() {
        color_echo("green", "Flathub added");
    }
}

fn install_rpm_fusion() {
    println!("Installing RPM Fusion...");

    let status = Command::new("sudo")
        .args(&[
            "dnf",
            "install",
            "-y",
            "rpmfusion-free-release",
            "rpmfusion-nonfree-release",
        ])
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .expect("Failed to install RPM Fusion");

    if status.success() {
        println!("RPM Fusion installed successfully");
    } else {
        eprintln!("Failed to install RPM Fusion");
    }
}

fn install_ffmpeg() {
    color_echo("yellow", "Installing FFmpeg...");
    let status = Command::new("sudo")
        .args(&["dnf", "swap", "ffmpeg-free", "ffmpeg", "--allowerasing", "-y"])
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()
        .expect("Failed to install FFmpeg");

    if status.success() {
        color_echo("green", "FFmpeg installed");
    } else {
        color_echo("red", "Failed to install FFmpeg");
    }
}

fn get_user_choice(prompt: &str, choices: &[&str]) -> usize {
    Select::new()
        .with_prompt(prompt)
        .items(choices)
        .default(0)
        .interact()
        .expect("Failed to read user input")
}

fn install_drivers(cpu_info: &str, gpu_info: &str) {
    if cpu_info == "INTEL" || gpu_info == "INTEL" {
        Command::new("sudo")
            .args(&["dnf", "install", "intel-media-driver", "-y"])
            .status()
            .expect("Failed to install Intel drivers");
    }

    if cpu_info == "AMD" || gpu_info == "AMD" {
        Command::new("sudo")
            .args(&["dnf", "swap", "mesa-va-drivers", "mesa-va-drivers-freeworld", "-y"])
            .status()
            .expect("Failed to install AMD drivers");
        Command::new("sudo")
            .args(&["dnf", "swap", "mesa-vdpau-drivers", "mesa-vdpau-drivers-freeworld", "-y"])
            .status()
            .expect("Failed to install AMD drivers");
    }

    if gpu_info == "NVIDIA" {
        color_echo("red", "Make sure you are on the latest kernel version!");
        color_echo("red", "Make sure secure boot is off.");
        Command::new("sudo")
            .args(&["dnf", "install", "akmod-nvidia", "xorg-x11-drv-nvidia-cuda", "-y"])
            .status()
            .expect("Failed to install NVIDIA drivers");
        color_echo("blue", "Wait for 5 minutes for the kernel modules to build or check the status using:");
        color_echo("blue", "modinfo -F version nvidia");
    }
}

fn configure_dnf() {
    if Confirm::new()
        .with_prompt("Do you want to do some tweaks to DNF (Recommended)?")
        .interact()
        .unwrap()
    {
        let status = Command::new("curl")
            .args(&["-o", "/tmp/dnf.conf", "https://raw.githubusercontent.com/Angxddeep/Fedora-Freedom/refs/heads/main/dnf.conf"])
            .status()
            .expect("Failed to download DNF configuration");

        if status.success() {
            Command::new("sudo")
                .args(&["cp", "/tmp/dnf.conf", "/etc/dnf/dnf.conf"])
                .status()
                .expect("Failed to update DNF configuration");
            color_echo("green", "DNF configuration updated.");
        } else {
            color_echo("red", "Failed to download DNF configuration.");
        }
    } else {
        color_echo("yellow", "No changes made to DNF configuration.");
    }
}

fn main() {
    color_echo("blue", "Fedora Setup Wizard");

    if Confirm::new()
        .with_prompt("Add Flathub?")
        .interact()
        .unwrap()
    {
        add_flathub();
    }

    if Confirm::new()
        .with_prompt("Install RPM Fusion?")
        .interact()
        .unwrap()
    {
        install_rpm_fusion();
    }

    install_ffmpeg();

    let cpu_choices = ["INTEL", "AMD"];
    let cpu_choice = get_user_choice("Select your CPU manufacturer:", &cpu_choices);
    let cpu_info = cpu_choices[cpu_choice];

    let gpu_choices = ["INTEL", "AMD", "NVIDIA"];
    let gpu_choice = get_user_choice("Select your GPU manufacturer:", &gpu_choices);
    let gpu_info = gpu_choices[gpu_choice];

    color_echo("yellow", "You have provided the following:");
    color_echo("red", &format!("CPU: {}", cpu_info));
    color_echo("red", &format!("GPU: {}", gpu_info));

    install_drivers(cpu_info, gpu_info);

    configure_dnf();
}
