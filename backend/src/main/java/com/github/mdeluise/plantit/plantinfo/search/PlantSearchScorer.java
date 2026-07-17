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

    private PlantSearchScorer() {
    }


    public static int score(String query, BotanicalInfo botanicalInfo) {
        int score = scoreName(query, botanicalInfo.getScientificName(), SCIENTIFIC_NAME_BASE);
        for (String synonym : botanicalInfo.getSynonyms()) {
            score = Math.max(score, scoreName(query, synonym, SYNONYM_BASE));
        }
        for (BotanicalCommonName commonName : botanicalInfo.getCommonNames()) {
            final int base = commonName.isPreferred() ? PREFERRED_COMMON_NAME_BASE : COMMON_NAME_BASE;
            score = Math.max(score, scoreName(query, commonName.getName(), base));
        }
        return score;
    }


    private static int scoreName(String query, String candidate, int base) {
        final String normalizedQuery = PlantNameNormalizer.normalize(query);
        final String normalizedCandidate = PlantNameNormalizer.normalize(candidate);
        if (normalizedQuery.isEmpty() || normalizedCandidate.isEmpty()) {
            return 0;
        }
        final int bonus;
        if (normalizedCandidate.equals(normalizedQuery)) {
            bonus = EXACT_MATCH;
        } else if (normalizedCandidate.startsWith(normalizedQuery)) {
            bonus = PREFIX_MATCH;
        } else if ((" " + normalizedCandidate + " ").contains(" " + normalizedQuery + " ")) {
            bonus = TOKEN_MATCH;
        } else if (containsEveryToken(normalizedQuery, normalizedCandidate)) {
            bonus = TOKEN_MATCH - normalizedCandidate.length() + normalizedQuery.length();
        } else if (normalizedCandidate.contains(normalizedQuery)) {
            bonus = CONTAINS_MATCH;
        } else {
            final int editDistance = minimumEditDistance(normalizedQuery, normalizedCandidate);
            bonus = editDistance <= MAX_EDIT_DISTANCE ? FUZZY_MATCH - editDistance : -base;
        }
        return Math.max(0, base + bonus);
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
