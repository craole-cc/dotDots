use std::{
    fs::{self, File},
    io::Read,
    process,
    time::{SystemTime, UNIX_EPOCH},
};

fn posix_cksum(bytes: &[u8]) -> u32 {
    let mut crc = 0_u32;

    for &byte in bytes {
        crc ^= u32::from(byte) << 24;
        for _ in 0..8 {
            crc = if crc & 0x8000_0000 != 0 {
                (crc << 1) ^ 0x04c1_1db7
            } else {
                crc << 1
            };
        }
    }

    let mut length = bytes.len();
    while length != 0 {
        crc ^= (length as u32 & 0xff) << 24;
        for _ in 0..8 {
            crc = if crc & 0x8000_0000 != 0 {
                (crc << 1) ^ 0x04c1_1db7
            } else {
                crc << 1
            };
        }
        length >>= 8;
    }

    !crc
}

fn parent_process_id() -> u32 {
    let stat = match fs::read_to_string("/proc/self/stat") {
        Ok(stat) => stat,
        Err(_) => return 0,
    };

    stat.rsplit_once(')')
        .and_then(|(_, fields)| fields.split_whitespace().nth(1))
        .and_then(|pid| pid.parse().ok())
        .unwrap_or_default()
}

fn random_suffix() -> u32 {
    let mut bytes = [0_u8; 4];
    File::open("/dev/urandom")
        .and_then(|mut file| file.read_exact(&mut bytes))
        .map(|()| posix_cksum(&bytes))
        .unwrap_or_default()
}

fn utc_date(days_since_epoch: i64) -> (i64, i64, i64) {
    let days = days_since_epoch + 719_468;
    let era = if days >= 0 { days } else { days - 146_096 } / 146_097;
    let day_of_era = days - era * 146_097;
    let year_of_era =
        (day_of_era - day_of_era / 1_460 + day_of_era / 36_524 - day_of_era / 146_096) / 365;
    let mut year = year_of_era + era * 400;
    let day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let month_prime = (5 * day_of_year + 2) / 153;
    let day = day_of_year - (153 * month_prime + 2) / 5 + 1;
    let month = month_prime + if month_prime < 10 { 3 } else { -9 };
    year += i64::from(month <= 2);

    (year, month, day)
}

fn main() {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or(1_000_000_001);
    let (year, month, day) = utc_date((seconds / 86_400) as i64);
    let seconds_of_day = seconds % 86_400;

    println!(
        "{year:04}{month:02}{day:02}{:02}{:02}{:02}_{:05}_{:05}_{:08x}",
        seconds_of_day / 3_600,
        (seconds_of_day % 3_600) / 60,
        seconds_of_day % 60,
        process::id(),
        parent_process_id(),
        random_suffix(),
    );
}
