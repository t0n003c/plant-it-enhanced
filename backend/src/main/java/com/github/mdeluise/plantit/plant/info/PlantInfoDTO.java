package com.github.mdeluise.plantit.plant.info;

import java.util.Date;
import java.util.Objects;

import com.github.mdeluise.plantit.plant.PlantState;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Plant info", description = "Represents additional info about a plant.")
public class PlantInfoDTO {
    @Schema(description = "Purchased date of the plant.")
    private Date startDate;
    @Schema(description = "Personal name of the plant.")
    private String personalName;
    @Schema(description = "End date of the plant.")
    private Date endDate;
    @Schema(description = "State of the plant.")
    private PlantState state;
    @Schema(description = "Note of the plant.")
    private String note;
    @Schema(description = "Price of the plant when purchased.")
    private Double purchasedPrice;
    @Schema(description = "Currency of the purchased price.")
    private String currencySymbol;
    @Schema(description = "Seller of the plant.")
    private String seller;
    @Schema(description = "Physical location of the plant.")
    private String location;
    @Schema(description = "INDOOR, OUTDOOR, or GREENHOUSE growing environment.")
    private String growingEnvironment;
    @Schema(description = "Observed LOW, MEDIUM, or HIGH light exposure.")
    private String lightExposure;
    @Schema(description = "Nearest window direction when grown indoors.")
    private String windowDirection;
    @Schema(description = "Pot diameter in centimeters.")
    private Double potDiameterCm;
    @Schema(description = "Pot material such as PLASTIC, TERRACOTTA, or GLAZED.")
    private String potMaterial;
    @Schema(description = "Whether the container has a drainage hole.")
    private Boolean hasDrainage;
    @Schema(description = "User-described soil or growing medium.")
    private String soilType;
    @Schema(description = "Most recent watering date.")
    private Date lastWateredAt;
    @Schema(description = "Most recent repotting date.")
    private Date lastRepottedAt;
    @Schema(description = "Optional approximate latitude for outdoor weather advice.")
    private Double latitude;
    @Schema(description = "Optional approximate longitude for outdoor weather advice.")
    private Double longitude;


    public Date getStartDate() {
        return startDate;
    }


    public void setStartDate(Date startDate) {
        this.startDate = startDate;
    }


    public String getPersonalName() {
        return personalName;
    }


    public void setPersonalName(String personalName) {
        this.personalName = personalName;
    }


    public Date getEndDate() {
        return endDate;
    }


    public void setEndDate(Date endDate) {
        this.endDate = endDate;
    }


    public PlantState getState() {
        return state;
    }


    public void setState(PlantState state) {
        this.state = state;
    }


    public String getNote() {
        return note;
    }


    public void setNote(String note) {
        this.note = note;
    }


    public Double getPurchasedPrice() {
        return purchasedPrice;
    }


    public void setPurchasedPrice(Double purchasedPrice) {
        this.purchasedPrice = purchasedPrice;
    }


    public String getCurrencySymbol() {
        return currencySymbol;
    }


    public void setCurrencySymbol(String currencySymbol) {
        this.currencySymbol = currencySymbol;
    }


    public String getSeller() {
        return seller;
    }


    public void setSeller(String seller) {
        this.seller = seller;
    }


    public String getLocation() {
        return location;
    }


    public void setLocation(String location) {
        this.location = location;
    }


    public String getGrowingEnvironment() {
        return growingEnvironment;
    }


    public void setGrowingEnvironment(String growingEnvironment) {
        this.growingEnvironment = growingEnvironment;
    }


    public String getLightExposure() {
        return lightExposure;
    }


    public void setLightExposure(String lightExposure) {
        this.lightExposure = lightExposure;
    }


    public String getWindowDirection() {
        return windowDirection;
    }


    public void setWindowDirection(String windowDirection) {
        this.windowDirection = windowDirection;
    }


    public Double getPotDiameterCm() {
        return potDiameterCm;
    }


    public void setPotDiameterCm(Double potDiameterCm) {
        this.potDiameterCm = potDiameterCm;
    }


    public String getPotMaterial() {
        return potMaterial;
    }


    public void setPotMaterial(String potMaterial) {
        this.potMaterial = potMaterial;
    }


    public Boolean getHasDrainage() {
        return hasDrainage;
    }


    public void setHasDrainage(Boolean hasDrainage) {
        this.hasDrainage = hasDrainage;
    }


    public String getSoilType() {
        return soilType;
    }


    public void setSoilType(String soilType) {
        this.soilType = soilType;
    }


    public Date getLastWateredAt() {
        return lastWateredAt;
    }


    public void setLastWateredAt(Date lastWateredAt) {
        this.lastWateredAt = lastWateredAt;
    }


    public Date getLastRepottedAt() {
        return lastRepottedAt;
    }


    public void setLastRepottedAt(Date lastRepottedAt) {
        this.lastRepottedAt = lastRepottedAt;
    }


    public Double getLatitude() {
        return latitude;
    }


    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }


    public Double getLongitude() {
        return longitude;
    }


    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }


    @SuppressWarnings("BooleanExpressionComplexity") //FIXME
    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        final PlantInfoDTO that = (PlantInfoDTO) o;
        return Objects.equals(startDate, that.startDate) && Objects.equals(personalName, that.personalName) &&
                   Objects.equals(endDate, that.endDate) && state == that.state &&
                   Objects.equals(note, that.note) && Objects.equals(purchasedPrice, that.purchasedPrice) &&
                   Objects.equals(currencySymbol, that.currencySymbol) && Objects.equals(seller, that.seller) &&
                   Objects.equals(location, that.location) &&
                   Objects.equals(growingEnvironment, that.growingEnvironment) &&
                   Objects.equals(lightExposure, that.lightExposure) &&
                   Objects.equals(windowDirection, that.windowDirection) &&
                   Objects.equals(potDiameterCm, that.potDiameterCm) &&
                   Objects.equals(potMaterial, that.potMaterial) && Objects.equals(hasDrainage, that.hasDrainage) &&
                   Objects.equals(soilType, that.soilType) && Objects.equals(lastWateredAt, that.lastWateredAt) &&
                   Objects.equals(lastRepottedAt, that.lastRepottedAt) && Objects.equals(latitude, that.latitude) &&
                   Objects.equals(longitude, that.longitude);
    }


    @Override
    public int hashCode() {
        return Objects.hash(startDate, personalName, endDate, state, note, purchasedPrice, currencySymbol, seller,
                            location, growingEnvironment, lightExposure, windowDirection, potDiameterCm, potMaterial,
                            hasDrainage, soilType, lastWateredAt, lastRepottedAt, latitude, longitude
        );
    }
}
