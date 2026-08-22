//
//  ActionItem+Enrichment.swift
//  Protocare
//
//  Action enrichment helpers for resolving substances
//

import Foundation

extension ActionItem {
    /// Resolves the substance for this action from the provided substances list
    /// - Parameter substances: Array of available substances to search
    /// - Returns: The resolved substance (either from self or looked up by substanceId)
    func resolvingSubstance(from substances: [Substance]) -> Substance? {
        self.substance ?? substances.first { $0.id == self.substanceId }
    }
    
    /// Creates a copy of this action with the substance resolved from the provided list
    /// - Parameter substances: Array of available substances to search
    /// - Returns: New ActionItem with resolved substance
    func enriched(with substances: [Substance]) -> ActionItem {
        ActionItem(
            id: self.id,
            name: self.name,
            substanceId: self.substanceId,
            substance: self.resolvingSubstance(from: substances),
            volume: self.volume,
            durationSeconds: self.durationSeconds
        )
    }
}

extension Array where Element == ActionItem {
    /// Enriches all actions in the array with substances from the provided list
    /// - Parameter substances: Array of available substances to search
    /// - Returns: New array of ActionItems with resolved substances
    func enriched(with substances: [Substance]) -> [ActionItem] {
        self.map { $0.enriched(with: substances) }
    }
}
