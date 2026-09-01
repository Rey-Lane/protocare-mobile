//
//  Action+Enrichment.swift
//  Protocare
//
//  Action enrichment helpers for resolving substances and converting to ActionItem
//

import Foundation

extension Action {
    /// Converts Action to ActionItem for UI presentation
    /// - Parameter substances: Array of available substances to lookup
    /// - Returns: ActionItem enriched with substance information
    func toActionItem(using substances: [Substance]) -> ActionItem {
        let substance = substances.first { $0.id == self.substanceId }
        return ActionItem(
            id: self.id,
            name: substance?.name ?? self.name,
            substanceId: self.substanceId,
            substance: substance,
            volume: self.defaultVolume,
            durationSeconds: self.defaultDurationSeconds,
            category: self.category,
            modality: self.modality,
            defaultParameters: self.defaultParameters,
            isLibrary: self.isLibrary
        )
    }
}

extension Array where Element == Action {
    /// Converts all Actions to ActionItems using provided substances
    /// - Parameter substances: Array of available substances
    /// - Returns: Array of enriched ActionItems
    func toActionItems(using substances: [Substance]) -> [ActionItem] {
        self.map { $0.toActionItem(using: substances) }
    }
}
