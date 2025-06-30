import os
import time
import logging
import json
import platform
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import psutil
try:
    import winreg
except ImportError:
    winreg = None  # Registry monitoring not available on non-Windows systems

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename='appv_monitor.log',
    filemode='w'
)

# Store events for App-V Sequencer compatibility
appv_changes = {
    "files": [],
    "registry": [],
    "services": [],
    "processes": []
}

class FileSystemMonitor(FileSystemEventHandler):
    """Handler for file system events."""
    def on_created(self, event):
        log_event("File Created", event.src_path, "files")
    
    def on_modified(self, event):
        log_event("File Modified", event.src_path, "files")
    
    def on_deleted(self, event):
        log_event("File Deleted", event.src_path, "files")

def log_event(event_type, details, category, process_info=None):
    """Log events to file and in-memory structure for App-V."""
    event = {
        "timestamp": time.ctime(),
        "event_type": event_type,
        "details": details,
        "process_info": process_info or get_process_info()
    }
    appv_changes[category].append(event)
    logging.info(f"{event_type}: {details} | Process: {process_info}")

def get_process_info():
    """Get information about the current process."""
    try:
        process = psutil.Process()
        return {
            "pid": process.pid,
            "name": process.name(),
            "exe": process.exe()
        }
    except Exception as e:
        return {"error": str(e)}

def monitor_file_system(paths):
    """Monitor specified file system paths for changes."""
    observer = Observer()
    event_handler = FileSystemMonitor()
    
    for path in paths:
        if os.path.exists(path):
            observer.schedule(event_handler, path, recursive=True)
            logging.info(f"Monitoring path: {path}")
        else:
            logging.warning(f"Path does not exist: {path}")
    
    observer.start()
    return observer

def monitor_registry(registry_keys):
    """Monitor Windows registry changes."""
    if platform.system() != "Windows" or not winreg:
        logging.warning("Registry monitoring is only supported on Windows.")
        return
    
    def check_registry_key(hive, key_path):
        try:
            key = winreg.OpenKey(hive, key_path, 0, winreg.KEY_READ)
            last_modified = winreg.QueryInfoKey(key)[2]
            return key, last_modified
        except Exception as e:
            logging.error(f"Error accessing registry key {key_path}: {e}")
            return None, None
    
    registry_state = {}
    for hive, key_path in registry_keys:
        key, last_modified = check_registry_key(hive, key_path)
        if key:
            registry_state[key_path] = last_modified
            winreg.CloseKey(key)
    
    while True:
        time.sleep(1)
        for hive, key_path in registry_keys:
            key, new_modified = check_registry_key(hive, key_path)
            if key and key_path in registry_state and new_modified != registry_state[key_path]:
                log_event("Registry Modified", f"{key_path} modified", "registry")
                registry_state[key_path] = new_modified
            if key:
                winreg.CloseKey(key)

def monitor_services():
    """Monitor Windows services for changes."""
    initial_services = {s.name(): s.as_dict() for s in psutil.win_service_iter()}
    
    while True:
        time.sleep(5)
        current_services = {s.name(): s.as_dict() for s in psutil.win_service_iter()}
        for name, info in current_services.items():
            if name not in initial_services:
                log_event("Service Created", f"Service: {name}, Path: {info['binpath']}", "services")
            elif initial_services[name] != info:
                log_event("Service Modified", f"Service: {name}, Path: {info['binpath']}", "services")
        for name in initial_services:
            if name not in current_services:
                log_event("Service Deleted", f"Service: {name}", "services")
        initial_services.update(current_services)

def save_appv_report(output_file):
    """Save captured changes to a JSON file for App-V Sequencer."""
    with open(output_file, 'w') as f:
        json.dump(appv_changes, f, indent=4)
    logging.info(f"App-V report saved to {output_file}")

def main():
    # Paths to monitor (customize for App-V sequencing)
    monitor_paths = [
        r"C:\Program Files",
        r"C:\Program Files (x86)",
        os.path.expanduser(r"~\AppData\Local"),
        os.path.expanduser(r"~\AppData\Roaming")
    ]
    
    # Registry keys to monitor
    registry_keys = [
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE"),
        (winreg.HKEY_CURRENT_USER, r"SOFTWARE")
    ]
    
    # Start file system monitoring
    observer = monitor_file_system(monitor_paths)
    
    # Start registry and service monitoring in separate threads
    if platform.system() == "Windows":
        import threading
        registry_thread = threading.Thread(target=monitor_registry, args=(registry_keys,), daemon=True)
        services_thread = threading.Thread(target=monitor_services, daemon=True)
        registry_thread.start()
        services_thread.start()
    
    try:
        print("Monitoring system changes for App-V package creation... Press Ctrl+C to stop.")
        print("Start the application installation now.")
        time.sleep(3600)  # Monitor for 1 hour (adjust as needed)
    except KeyboardInterrupt:
        observer.stop()
        logging.info("Monitoring stopped by user.")
    
    observer.join()
    save_appv_report("appv_changes.json")
    
    # Instructions for App-V Sequencer
    print("\nNext Steps for App-V Package Creation:")
    print("1. Open the App-V Sequencer on a clean virtual machine.")
    print("2. Start a new sequencing project and install the application while the Sequencer is monitoring.")
    print("3. Use the 'appv_changes.json' report to verify captured changes.")
    print("4. Save the App-V package (.appv, .msi, .xml files) in the Sequencer.")

if __name__ == "__main__":
    main()
