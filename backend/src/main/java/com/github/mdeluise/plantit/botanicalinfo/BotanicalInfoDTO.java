package com.github.mdeluise.plantit.botanicalinfo;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfoDTO;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationEvidence;
import com.github.mdeluise.plantit.plantinfo.identification.PlantLookalike;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Botanical info", description = "Represents a plant's botanical info.")
public class BotanicalInfoDTO {
    @Schema(description = "ID of the botanical info.", accessMode = Schema.AccessMode.READ_ONLY)
    private Long id;
    @Schema(description = "Scientific name of the botanical info.", accessMode = Schema.AccessMode.READ_ONLY)
    private String scientificName;
    @Schema(description = "Synonyms of the botanical info.")
    private Set<String> synonyms = new HashSet<>();
    @Schema(description = "Preferred localized common name.", accessMode = Schema.AccessMode.READ_ONLY)
    private String preferredCommonName;
    @Schema(description = "Localized common names and their sources.")
    private Set<BotanicalCommonNameDTO> commonNames = new LinkedHashSet<>();
    @Schema(description = "Provider identifiers used to verify this taxon.")
    private Map<String, String> externalReferences = new HashMap<>();
    @Schema(description = "Stable accepted GBIF taxon key used to merge provider records.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private String canonicalTaxonKey;
    @Schema(description = "Last time external taxonomy was verified.")
    private Instant lastVerifiedAt;
    @Schema(description = "Family of the botanical info.")
    private String family;
    @Schema(description = "Genus of the botanical info.")
    private String genus;
    @Schema(description = "Species of the botanical info.")
    private String species;
    @Schema(description = "Care information of the botanical info.")
    private PlantCareInfoDTO plantCareInfo;
    @Schema(description = "ID of the botanical info image.", accessMode = Schema.AccessMode.READ_ONLY)
    private String imageId;
    @Schema(description = "URL of the botanical info image.")
    private String imageUrl;
    @Schema(description = "Fallback URL used when the preferred botanical image is unavailable.")
    private String imageFallbackUrl;
    @Schema(description = "Provider of the botanical image.", accessMode = Schema.AccessMode.READ_ONLY)
    private String imageSource;
    @Schema(description = "Source page for the botanical image.", accessMode = Schema.AccessMode.READ_ONLY)
    private String imageSourceUrl;
    @Schema(description = "License code supplied by the botanical image provider.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private String imageLicenseCode;
    @Schema(description = "Attribution supplied by the botanical image provider.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private String imageAttribution;
    @Schema(description = "Content of the botanical info image.", accessMode = Schema.AccessMode.WRITE_ONLY)
    private byte[] imageContent;
    @Schema(description = "Content type of the botanical info image.", accessMode = Schema.AccessMode.WRITE_ONLY)
    private String imageContentType;
    @Schema(description = "Creator of the botanical info")
    private String creator;
    @Schema(description = "ID of the botanical info in the creator service")
    private String externalId;
    @Schema(description = "Confidence assigned by a photo-identification provider.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private Double identificationConfidence;
    @Schema(description = "Photo-identification provider.", accessMode = Schema.AccessMode.READ_ONLY)
    private String identificationProvider;
    @Schema(description = "Photo-identification model version.", accessMode = Schema.AccessMode.READ_ONLY)
    private String identificationModel;
    @Schema(description = "Geographic or thematic flora used for photo identification.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private String identificationProject;
    @Schema(description = "Display title of the flora used for photo identification.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private String identificationProjectTitle;
    @Schema(description = "Provider confidence with small, attributable contextual adjustments.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private Double contextualIdentificationScore;
    @Schema(description = "Signals considered when contextually ranking an identification.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private List<PlantIdentificationEvidence> identificationEvidence = new ArrayList<>();
    @Schema(description = "Reviewed, attributable taxa commonly confused with this identification.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private List<PlantLookalike> reviewedLookalikes = new ArrayList<>();
    @Schema(description = "Attributable regional establishment status, when available.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private String establishmentMeans;
    @Schema(description = "Place to which the establishment status applies.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private String establishmentPlace;
    @Schema(description = "Why this result matched the search query.", accessMode = Schema.AccessMode.READ_ONLY)
    private String searchMatchReason;
    @Schema(description = "Search relevance confidence from zero to one.", accessMode = Schema.AccessMode.READ_ONLY)
    private Double searchMatchConfidence;
    @Schema(description = "Plant name that best matched the search query.", accessMode = Schema.AccessMode.READ_ONLY)
    private String searchMatchedName;
    @Schema(description = "Reviewed catalog collections containing this plant.",
            accessMode = Schema.AccessMode.READ_ONLY)
    private Set<String> catalogTags = new LinkedHashSet<>();


    public Long getId() {
        return id;
    }


    public void setId(Long id) {
        this.id = id;
    }


    public String getScientificName() {
        return scientificName;
    }


    public void setScientificName(String scientificName) {
        this.scientificName = scientificName;
    }


    public Set<String> getSynonyms() {
        return synonyms;
    }


    public void setSynonyms(Set<String> synonyms) {
        this.synonyms = synonyms;
    }


    public String getPreferredCommonName() {
        return preferredCommonName;
    }


    public void setPreferredCommonName(String preferredCommonName) {
        this.preferredCommonName = preferredCommonName;
    }


    public Set<BotanicalCommonNameDTO> getCommonNames() {
        return commonNames;
    }


    public void setCommonNames(Set<BotanicalCommonNameDTO> commonNames) {
        this.commonNames = commonNames;
    }


    public Map<String, String> getExternalReferences() {
        return externalReferences;
    }


    public void setExternalReferences(Map<String, String> externalReferences) {
        this.externalReferences = externalReferences;
    }


    public String getCanonicalTaxonKey() {
        return canonicalTaxonKey;
    }


    public void setCanonicalTaxonKey(String canonicalTaxonKey) {
        this.canonicalTaxonKey = canonicalTaxonKey;
    }


    public Instant getLastVerifiedAt() {
        return lastVerifiedAt;
    }


    public void setLastVerifiedAt(Instant lastVerifiedAt) {
        this.lastVerifiedAt = lastVerifiedAt;
    }


    public String getFamily() {
        return family;
    }


    public void setFamily(String family) {
        this.family = family;
    }


    public String getGenus() {
        return genus;
    }


    public void setGenus(String genus) {
        this.genus = genus;
    }


    public String getSpecies() {
        return species;
    }


    public void setSpecies(String species) {
        this.species = species;
    }


    public PlantCareInfoDTO getPlantCareInfo() {
        return plantCareInfo;
    }


    public void setPlantCareInfo(PlantCareInfoDTO plantCareInfo) {
        this.plantCareInfo = plantCareInfo;
    }


    public String getImageUrl() {
        return imageUrl;
    }


    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }


    public String getImageFallbackUrl() {
        return imageFallbackUrl;
    }


    public void setImageFallbackUrl(String imageFallbackUrl) {
        this.imageFallbackUrl = imageFallbackUrl;
    }


    public String getImageSource() {
        return imageSource;
    }


    public void setImageSource(String imageSource) {
        this.imageSource = imageSource;
    }


    public String getImageSourceUrl() {
        return imageSourceUrl;
    }


    public void setImageSourceUrl(String imageSourceUrl) {
        this.imageSourceUrl = imageSourceUrl;
    }


    public String getImageLicenseCode() {
        return imageLicenseCode;
    }


    public void setImageLicenseCode(String imageLicenseCode) {
        this.imageLicenseCode = imageLicenseCode;
    }


    public String getImageAttribution() {
        return imageAttribution;
    }


    public void setImageAttribution(String imageAttribution) {
        this.imageAttribution = imageAttribution;
    }


    public String getImageId() {
        return imageId;
    }


    public void setImageId(String imageId) {
        this.imageId = imageId;
    }


    public byte[] getImageContent() {
        return imageContent;
    }


    public void setImageContent(byte[] imageContent) {
        this.imageContent = imageContent;
    }


    public String getImageContentType() {
        return imageContentType;
    }


    public void setImageContentType(String imageContentType) {
        this.imageContentType = imageContentType;
    }


    public void setCreator(String creator) {
        this.creator = creator;
    }


    public String getCreator() {
        return creator;
    }


    public String getExternalId() {
        return externalId;
    }


    public void setExternalId(String externalId) {
        this.externalId = externalId;
    }


    public Double getIdentificationConfidence() {
        return identificationConfidence;
    }


    public void setIdentificationConfidence(Double identificationConfidence) {
        this.identificationConfidence = identificationConfidence;
    }


    public String getIdentificationProvider() {
        return identificationProvider;
    }


    public void setIdentificationProvider(String identificationProvider) {
        this.identificationProvider = identificationProvider;
    }


    public String getIdentificationModel() {
        return identificationModel;
    }


    public void setIdentificationModel(String identificationModel) {
        this.identificationModel = identificationModel;
    }


    public String getIdentificationProject() {
        return identificationProject;
    }


    public void setIdentificationProject(String identificationProject) {
        this.identificationProject = identificationProject;
    }


    public String getIdentificationProjectTitle() {
        return identificationProjectTitle;
    }


    public void setIdentificationProjectTitle(String identificationProjectTitle) {
        this.identificationProjectTitle = identificationProjectTitle;
    }


    public Double getContextualIdentificationScore() {
        return contextualIdentificationScore;
    }


    public void setContextualIdentificationScore(Double contextualIdentificationScore) {
        this.contextualIdentificationScore = contextualIdentificationScore;
    }


    public List<PlantIdentificationEvidence> getIdentificationEvidence() {
        return identificationEvidence;
    }


    public void setIdentificationEvidence(List<PlantIdentificationEvidence> identificationEvidence) {
        this.identificationEvidence = identificationEvidence == null ? new ArrayList<>() : identificationEvidence;
    }


    public List<PlantLookalike> getReviewedLookalikes() {
        return reviewedLookalikes;
    }


    public void setReviewedLookalikes(List<PlantLookalike> reviewedLookalikes) {
        this.reviewedLookalikes = reviewedLookalikes == null ? new ArrayList<>() : reviewedLookalikes;
    }


    public String getEstablishmentMeans() {
        return establishmentMeans;
    }


    public void setEstablishmentMeans(String establishmentMeans) {
        this.establishmentMeans = establishmentMeans;
    }


    public String getEstablishmentPlace() {
        return establishmentPlace;
    }


    public void setEstablishmentPlace(String establishmentPlace) {
        this.establishmentPlace = establishmentPlace;
    }


    public String getSearchMatchReason() {
        return searchMatchReason;
    }


    public void setSearchMatchReason(String searchMatchReason) {
        this.searchMatchReason = searchMatchReason;
    }


    public Double getSearchMatchConfidence() {
        return searchMatchConfidence;
    }


    public void setSearchMatchConfidence(Double searchMatchConfidence) {
        this.searchMatchConfidence = searchMatchConfidence;
    }


    public String getSearchMatchedName() {
        return searchMatchedName;
    }


    public void setSearchMatchedName(String searchMatchedName) {
        this.searchMatchedName = searchMatchedName;
    }


    public Set<String> getCatalogTags() {
        return catalogTags;
    }


    public void setCatalogTags(Set<String> catalogTags) {
        this.catalogTags = catalogTags == null ? new LinkedHashSet<>() : catalogTags;
    }


    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        final BotanicalInfoDTO that = (BotanicalInfoDTO) o;
        return Objects.equals(id, that.id) || Objects.equals(species, that.species);
    }


    @Override
    public int hashCode() {
        return Objects.hash(id, species);
    }
}
