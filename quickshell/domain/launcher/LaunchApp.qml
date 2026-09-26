pragma Singleton

import Quickshell
import qs.data.applications
import qs.data.usage

Singleton {
    id: root

    function execute(entry): void {
        if (!entry)
            return;

        UsageRepository.record(entry.id);
        AppRepository.launch(entry);
    }
}