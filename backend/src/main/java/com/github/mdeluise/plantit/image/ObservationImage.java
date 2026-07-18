package com.github.mdeluise.plantit.image;

import com.github.mdeluise.plantit.observation.Observation;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import org.hibernate.validator.constraints.Length;

@Entity
@DiscriminatorValue("3")
public class ObservationImage extends EntityImageImpl {
    @ManyToOne
    @JoinColumn(name = "observation_entity_id")
    private Observation target;
    @Length(max = 64)
    private String clientReference;


    public Observation getTarget() {
        return target;
    }


    public void setTarget(Observation target) {
        this.target = target;
    }


    public String getClientReference() {
        return clientReference;
    }


    public void setClientReference(String clientReference) {
        this.clientReference = clientReference;
    }
}
