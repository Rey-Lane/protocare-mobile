//
//  Action+Enrichment.swift
//  Protocare
//
//  Unified action model (Step 25a): Action carries name/category/modality/
//  default_parameters itself — no substance lookup is needed anymore.
//

import Foundation

extension Action {
    /// Converts the unified Action to an ActionItem for UI presentation.
    public func toActionItem() -> ActionItem {
        ActionItem(
            id: id,
            name: name,
            substanceId: substanceId,
            substance: nil,
            volume: defaultVolume,
            durationSeconds: defaultDurationSeconds,
            category: category,
            modality: modality,
            defaultParameters: defaultParameters,
            isLibrary: isLibrary
        )
    }
}

extension Array where Element == Action {
    /// Converts all unified Actions to ActionItems.
    public func toActionItems() -> [ActionItem] {
        self.map { $0.toActionItem() }
    }
}
