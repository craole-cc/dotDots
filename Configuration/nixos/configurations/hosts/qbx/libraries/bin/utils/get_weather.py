import json
import os
import sys
import argparse
from datetime import datetime
from urllib.error import URLError
from urllib.parse import quote
from urllib.request import Request, urlopen
import logging

class WeatherCache:
    def __init__(self, cache_file="/tmp/weather_cache.json", cache_duration=60):
        self.cache_file = cache_file
        self.cache_duration = cache_duration
        self.memory_cache = {}
        self.logger = None

    def setup_logger(self, debug=False):
        """Configure logger based on debug flag."""
        if not debug:
            return logging.getLogger('null')

        logger = logging.getLogger('WeatherCache')
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        return logger

    def get(self, location, logger, ignore_cache=False):
        """Retrieve cached weather data for a location."""
        if ignore_cache:
            logger.info(f"Cache ignored for {location}")
            return None

        cache_key = f"temp_{location}"
        time_key = f"time_{location}"

        # Check memory cache
        if (cache_key in self.memory_cache and
            datetime.now().timestamp() - self.memory_cache.get(time_key, 0) < self.cache_duration * 60):
            logger.info(f"Retrieved {location} weather from memory cache")
            return self.memory_cache[cache_key]

        # Check file cache
        try:
            if os.path.exists(self.cache_file):
                with open(self.cache_file, 'r') as f:
                    file_cache = json.load(f)
                    if (cache_key in file_cache and
                        datetime.now().timestamp() - file_cache.get(time_key, 0) < self.cache_duration * 60):
                        self.memory_cache.update(file_cache)
                        logger.info(f"Retrieved {location} weather from file cache")
                        return file_cache[cache_key]
        except (IOError, json.JSONDecodeError) as e:
            logger.error(f"Cache read error: {e}")

        return None

    def save(self, temperature, location, logger):
        """Save weather data to cache."""
        cache_key = f"temp_{location}"
        time_key = f"time_{location}"
        current_time = datetime.now().timestamp()

        # Update memory cache
        self.memory_cache.update({
            cache_key: temperature,
            time_key: current_time
        })

        # Update file cache
        try:
            existing_cache = {}
            if os.path.exists(self.cache_file):
                with open(self.cache_file, 'r') as f:
                    existing_cache = json.load(f)

            existing_cache.update(self.memory_cache)
            with open(self.cache_file, 'w') as f:
                json.dump(existing_cache, f)

            logger.info(f"Cached temperature for {location}")
        except (IOError, PermissionError) as e:
            logger.error(f"Cache write error: {e}")

def fetch_weather(location="Mandeville,Jamaica", timeout=5, format_num="4", debug=False, ignore_cache=False):
    """
    Fetch weather for a given location.

    Args:
        location (str): Location to fetch weather for
        timeout (int): Request timeout in seconds
        format_num (str): Weather format (1-4)
        debug (bool): Enable debug logging
        ignore_cache (bool): Bypass cache

    Returns:
        str: Temperature or 'N/A' if fetch fails
    """
    cache = WeatherCache()
    logger = cache.setup_logger(debug)

    # Check cache first
    cached_temp = cache.get(location, logger, ignore_cache)
    if cached_temp:
        return cached_temp

    try:
        headers = {'Accept-Encoding': 'gzip, deflate'}
        encoded_location = quote(location)
        url = f"https://wttr.in/{encoded_location}?format={format_num}"

        request = Request(url, headers=headers)
        with urlopen(request, timeout=timeout) as response:
            temperature = response.read().decode('utf-8').strip()

            # Only cache if temperature looks valid
            if temperature and not temperature.startswith('N/A'):
                cache.save(temperature, location, logger)

            return temperature
    except (URLError, TimeoutError) as e:
        logger.error(f"Weather fetch error for {location}: {e}")
        return "N/A"

def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(description='Fetch weather for a location')
    parser.add_argument('location', nargs='?', default="Mandeville,Jamaica", help='Location to fetch weather for')
    parser.add_argument('--format', choices=['1', '2', '3', '4'], default='4', help='Weather format (1-4)')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    parser.add_argument('--no-cache', action='store_true', help='Ignore cache and fetch fresh data')

    args = parser.parse_args()

    print(fetch_weather(
        location=args.location,
        format_num=args.format,
        debug=args.debug,
        ignore_cache=args.no_cache
    ))

if __name__ == "__main__":
    main()
