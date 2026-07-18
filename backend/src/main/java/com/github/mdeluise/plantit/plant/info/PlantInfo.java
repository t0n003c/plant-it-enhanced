package com.github.mdeluise.plantit.plant.info;

import java.io.Serializable;
import java.util.Date;
import java.util.Objects;

import com.github.mdeluise.plantit.plant.PlantState;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.validation.constraints.NotBlank;
import org.hibernate.validator.constraints.Length;

@Embeddable
public class PlantInfo implements Serializable {
    private Date startDate;
    @NotBlank
    @Length(max = 30)
    private String personalName;
    private Date endDate;
    @Enumerated(EnumType.STRING)
    private PlantState plantState;
    @Length(max = 8500)
    private String note;
    private Double purchasedPrice;
    @Length(max = 4)
    private String currencySymbol;
    @Length(max = 100)
    private String seller;
    @Length(max = 100)
    private String location;
    @Length(max = 16)
    private String growingEnvironment;
    @Length(max = 16)
    private String lightExposure;
    @Length(max = 8)
    private String windowDirection;
    private Double potDiameterCm;
    @Length(max = 24)
    private String potMaterial;
    private Boolean hasDrainage;
    @Length(max = 100)
    private String soilType;
    private Date lastWateredAt;
    private Date lastRepottedAt;
    private Double latitude;
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


    public PlantState getPlantState() {
        return plantState;
    }


    public void setPlantState(PlantState plantState) {
        this.plantState = plantState;
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


    public String getCurrencySymbol() {
        return currencySymbol;
    }


    public void setCurrencySymbol(String currencySymbol) {
        this.currencySymbol = currencySymbol;
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
        final PlantInfo plantInfo = (PlantInfo) o;
        return Objects.equals(startDate, plantInfo.startDate) && Objects.equals(personalName, plantInfo.personalName) &&
                   Objects.equals(endDate, plantInfo.endDate) && plantState == plantInfo.plantState &&
                   Objects.equals(note, plantInfo.note) && Objects.equals(purchasedPrice, plantInfo.purchasedPrice) &&
                   Objects.equals(currencySymbol, plantInfo.currencySymbol) &&
                   Objects.equals(seller, plantInfo.seller) && Objects.equals(location, plantInfo.location) &&
                   Objects.equals(growingEnvironment, plantInfo.growingEnvironment) &&
                   Objects.equals(lightExposure, plantInfo.lightExposure) &&
                   Objects.equals(windowDirection, plantInfo.windowDirection) &&
                   Objects.equals(potDiameterCm, plantInfo.potDiameterCm) &&
                   Objects.equals(potMaterial, plantInfo.potMaterial) &&
                   Objects.equals(hasDrainage, plantInfo.hasDrainage) && Objects.equals(soilType, plantInfo.soilType) &&
                   Objects.equals(lastWateredAt, plantInfo.lastWateredAt) &&
                   Objects.equals(lastRepottedAt, plantInfo.lastRepottedAt) &&
                   Objects.equals(latitude, plantInfo.latitude) && Objects.equals(longitude, plantInfo.longitude);
    }


    @Override
    public int hashCode() {
        return Objects.hash(startDate, personalName, endDate, plantState, note, purchasedPrice, currencySymbol, seller,
                            location, growingEnvironment, lightExposure, windowDirection, potDiameterCm, potMaterial,
                            hasDrainage, soilType, lastWateredAt, lastRepottedAt, latitude, longitude
        );
    }
}
