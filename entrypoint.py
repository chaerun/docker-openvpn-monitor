#!/usr/bin/env python3
import os
import sys
import configparser

def format_key(key):
    # Map Rui Marinho's flat variables to the correct underscored config keys
    mapping = {
        'MAPS': 'enable_maps',
        'DATETIMEFORMAT': 'datetime_format',
        'MAPSHEIGHT': 'maps_height',
        'SHOWDISCONNECT': 'show_disconnect',
        'GEOIPDATA': 'geoip_data'
    }
    return mapping.get(key, key.lower())

def generate_config():
    config = configparser.RawConfigParser()
    config.optionxform = str  # Preserve case
    
    # --- CHANGED: Must be strictly lowercase to match the app's internal parser ---
    default_section = 'openvpn-monitor'
    config.add_section(default_section)
    
    for key, value in os.environ.items():
        if key.startswith('OPENVPNMONITOR_DEFAULT_'):
            prop = format_key(key.replace('OPENVPNMONITOR_DEFAULT_', ''))
            
            # Revert escaped formatting for dates (Docker passes %% but python config needs %)
            if value.startswith('%%'):
                value = value.replace('%%', '%')
                
            config.set(default_section, prop, value)

    # 2. Setup Site sections
    # Find all unique site indices (0, 1, 2, etc.)
    site_keys = [k for k in os.environ.keys() if k.startswith('OPENVPNMONITOR_SITES_')]
    site_indices = sorted(list(set([k.split('_')[2] for k in site_keys])))

    for index in site_indices:
        # Note: The site section names MUST remain capitalized like "Site 0"
        section_name = f'Site {index}'
        config.add_section(section_name)
        
        # Look for variables belonging to this specific site index
        prefix = f'OPENVPNMONITOR_SITES_{index}_'
        for key, value in os.environ.items():
            if key.startswith(prefix):
                prop = format_key(key.replace(prefix, ''))
                config.set(section_name, prop, value)

    # Write the config file
    os.makedirs('/etc/openvpn-monitor', exist_ok=True)
    with open('/etc/openvpn-monitor/openvpn-monitor.conf', 'w') as configfile:
        config.write(configfile)

if __name__ == '__main__':
    generate_config()
    
    # Exec into the main container command (gunicorn)
    if len(sys.argv) > 1:
        os.execvp(sys.argv[1], sys.argv[1:])
    else:
        os.execvp("gunicorn", ["gunicorn", "openvpn_monitor.app", "-b", "0.0.0.0:80"])