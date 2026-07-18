package com.github.mdeluise.plantit.plantinfo.search;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;

public final class PlantSearchScorer {
    private static final int PREFERRED_COMMON_NAME_BASE = 2000;
    private static final int COMMON_NAME_BASE = 1800;
    private static final int SYNONYM_BASE = 1400;
    private static final int SCIENTIFIC_NAME_BASE = 1000;
    private static final int EXACT_MATCH = 500;
    private static final int PREFIX_MATCH = 400;
    private static final int TOKEN_MATCH = 350;
    private static final int CONTAINS_MATCH = 300;
    private static final int FUZZY_MATCH = 200;
    private static final int MAX_EDIT_DISTANCE = 2;
    private static final double EXACT_COMMON_CONFIDENCE = 1.0;
    private static final double EXACT_SCIENTIFIC_CONFIDENCE = 0.96;
    private static final double EXACT_SYNONYM_CONFIDENCE = 0.92;
    private static final double WORD_PREFIX_CONFIDENCE = 0.82;
    private static final double FRAGMENT_PREFIX_CONFIDENCE = 0.38;
    private static final double TOKEN_CONFIDENCE = 0.78;
    private static final double ALL_KEYWORDS_CONFIDENCE = 0.76;
    private static final double CONTAINS_CONFIDENCE = 0.42;
    private static final double ONE_TYPO_CONFIDENCE = 0.82;
    private static final double TWO_TYPOS_CONFIDENCE = 0.68;

    private PlantSearchScorer() {
    }


    public static int score(String query, BotanicalInfo botanicalInfo) {
        return evaluate(query, botanicalInfo).score();
    }


    public static PlantSearchMatch evaluate(String query, BotanicalInfo botanicalInfo) {
        PlantSearchMatch best = scoreName(
            query, botanicalInfo.getScientificName(), SCIENTIFIC_NAME_BASE,
            PlantSearchMatchReason.SCIENTIFIC_NAME, EXACT_SCIENTIFIC_CONFIDENCE
        );
        for (String synonym : botanicalInfo.getSynonyms()) {
            best = better(best, scoreName(
                query, synonym, SYNONYM_BASE,
                PlantSearchMatchReason.SCIENTIFIC_SYNONYM, EXACT_SYNONYM_CONFIDENCE
            ));
        }
        for (BotanicalCommonName commonName : botanicalInfo.getCommonNames()) {
            final int base = commonName.isPreferred() ? PREFERRED_COMMON_NAME_BASE : COMMON_NAME_BASE;
            best = better(best, scoreName(
                query, commonName.getName(), base,
                PlantSearchMatchReason.EXACT_COMMON_NAME, EXACT_COMMON_CONFIDENCE
            ));
        }
        return best;
    }


    public static void applyMatchMetadata(String query, BotanicalInfo botanicalInfo) {
        final PlantSearchMatch match = evaluate(query, botanicalInfo);
        botanicalInfo.setSearchMatchReason(match.reason().name());
        botanicalInfo.setSearchMatchConfidence(match.confidence());
    }


    private static PlantSearchMatch better(PlantSearchMatch left, PlantSearchMatch right) {
        if (right.score() > left.score()) {
            return right;
        }
        if (right.score() == left.score() && right.confidence() > left.confidence()) {
            return right;
        }
        return left;
    }


    private static PlantSearchMatch scoreName(String query, String candidate, int base,
                                              PlantSearchMatchReason exactReason,
                                              double exactConfidence) {
        final String normalizedQuery = PlantNameNormalizer.normalize(query);
        final String normalizedCandidate = PlantNameNormalizer.normalize(candidate);
        if (normalizedQuery.isEmpty() || normalizedCandidate.isEmpty()) {
            return noMatch();
        }
        final int bonus;
        final double confidence;
        final PlantSearchMatchReason reason;
        if (normalizedCandidate.equals(normalizedQuery)) {
            bonus = EXACT_MATCH;
            confidence = exactConfidence;
            reason = exactReason;
        } else if (normalizedCandidate.startsWith(normalizedQuery)) {
            bonus = PREFIX_MATCH;
            final boolean endsAtWordBoundary = normalizedCandidate.length() > normalizedQuery.length() &&
                                                   normalizedCandidate.charAt(normalizedQuery.length()) == ' ';
            confidence = endsAtWordBoundary ? WORD_PREFIX_CONFIDENCE : FRAGMENT_PREFIX_CONFIDENCE;
            reason = exactReason == PlantSearchMatchReason.EXACT_COMMON_NAME
                         ? PlantSearchMatchReason.COMMON_NAME_PREFIX : PlantSearchMatchReason.PARTIAL_MATCH;
        } else if ((" " + normalizedCandidate + " ").contains(" " + normalizedQuery + " ")) {
            bonus = TOKEN_MATCH;
            confidence = TOKEN_CONFIDENCE;
            reason = keywordReason(exactReason);
        } else if (containsEveryToken(normalizedQuery, normalizedCandidate)) {
            bonus = TOKEN_MATCH - normalizedCandidate.length() + normalizedQuery.length();
            confidence = ALL_KEYWORDS_CONFIDENCE;
            reason = keywordReason(exactReason);
        } else if (normalizedCandidate.contains(normalizedQuery)) {
            bonus = CONTAINS_MATCH;
            confidence = CONTAINS_CONFIDENCE;
            reason = PlantSearchMatchReason.PARTIAL_MATCH;
        } else {
            final int editDistance = minimumEditDistance(normalizedQuery, normalizedCandidate);
            if (editDistance > MAX_EDIT_DISTANCE) {
                return noMatch();
            }
            bonus = FUZZY_MATCH - editDistance;
            confidence = editDistance == 1 ? ONE_TYPO_CONFIDENCE : TWO_TYPOS_CONFIDENCE;
            reason = exactReason == PlantSearchMatchReason.EXACT_COMMON_NAME
                         ? PlantSearchMatchReason.COMMON_NAME_TYPO : exactReason;
        }
        return new PlantSearchMatch(Math.max(0, base + bonus), confidence, reason);
    }


    private static PlantSearchMatchReason keywordReason(PlantSearchMatchReason exactReason) {
        return exactReason == PlantSearchMatchReason.EXACT_COMMON_NAME
                   ? PlantSearchMatchReason.COMMON_NAME_KEYWORDS : exactReason;
    }


    private static PlantSearchMatch noMatch() {
        return new PlantSearchMatch(0, 0, PlantSearchMatchReason.NONE);
    }


    private static int minimumEditDistance(String query, String candidate) {
        int minimum = editDistance(query, candidate);
        if (!query.contains(" ")) {
            for (String token : candidate.split(" ")) {
                minimum = Math.min(minimum, editDistance(query, token));
            }
        }
        return minimum;
    }


    private static boolean containsEveryToken(String query, String candidate) {
        final String paddedCandidate = " " + candidate + " ";
        for (String token : query.split(" ")) {
            if (!paddedCandidate.contains(" " + token + " ")) {
                return false;
            }
        }
        return true;
    }


    private static int editDistance(String left, String right) {
        int[] previous = new int[right.length() + 1];
        int[] current = new int[right.length() + 1];
        for (int index = 0; index <= right.length(); index++) {
            previous[index] = index;
        }
        for (int leftIndex = 1; leftIndex <= left.length(); leftIndex++) {
            current[0] = leftIndex;
            for (int rightIndex = 1; rightIndex <= right.length(); rightIndex++) {
                final int substitutionCost = left.charAt(leftIndex - 1) == right.charAt(rightIndex - 1) ? 0 : 1;
                current[rightIndex] = Math.min(
                    Math.min(current[rightIndex - 1] + 1, previous[rightIndex] + 1),
                    previous[rightIndex - 1] + substitutionCost
                );
            }
            final int[] swap = previous;
            previous = current;
            current = swap;
        }
        return previous[right.length()];
    }
}
