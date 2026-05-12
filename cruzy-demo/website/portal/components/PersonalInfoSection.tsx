'use client'

import { useRef, useEffect, useCallback } from 'react'
import { UseFormRegister, UseFormSetValue, FieldErrors } from 'react-hook-form'
import { FormValues } from '@/lib/schema'

const US_STATES = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA',
  'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
  'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT',
  'VA','WA','WV','WI','WY','DC',
]

const COUNTRIES = [
  'United States','Canada','Afghanistan','Aland Islands','Albania','Algeria',
  'American Samoa','Andorra','Angola','Anguilla','Antarctica','Antigua and Barbuda',
  'Argentina','Armenia','Aruba','Australia','Austria','Azerbaijan','Bahrain',
  'Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bermuda','Bhutan',
  'Bolivia','Bosnia and Herzegovina','Botswana','Brazil','Brunei','Bulgaria',
  'Burkina Faso','Burundi','Cambodia','Cameroon','Cape Verde','Cayman Islands',
  'Central African Republic','Chad','Chile','China','Colombia','Comoros','Congo',
  'Cook Islands','Costa Rica','Croatia','Cuba','Curaçao','Cyprus','Czech Republic',
  'Denmark','Djibouti','Dominica','Dominican Republic','Ecuador','Egypt',
  'El Salvador','Estonia','Ethiopia','Fiji Islands','Finland','France','Germany',
  'Ghana','Greece','Greenland','Guatemala','Haiti','Honduras','Hungary','Iceland',
  'India','Indonesia','Iran','Iraq','Ireland','Israel','Italy','Jamaica','Japan',
  'Jordan','Kazakhstan','Kenya','Kuwait','Laos','Latvia','Lebanon','Libya',
  'Lithuania','Luxembourg','Malaysia','Malta','Mexico','Moldova','Monaco',
  'Morocco','Mozambique','Myanmar','Nepal','Netherlands','New Zealand','Nicaragua',
  'Nigeria','Norway','Oman','Pakistan','Panama','Paraguay','Peru','Philippines',
  'Poland','Portugal','Puerto Rico','Qatar','Romania','Russia','Saudi Arabia',
  'Serbia','Singapore','Slovakia','Slovenia','Somalia','South Africa','South Korea',
  'Spain','Sri Lanka','Sudan','Sweden','Switzerland','Syria','Taiwan','Tanzania',
  'Thailand','Trinidad and Tobago','Tunisia','Turkey','Uganda','Ukraine',
  'United Arab Emirates','United Kingdom','Uruguay','Venezuela','Vietnam',
  'Virgin Islands (US)','Yemen','Zambia','Zimbabwe',
]

interface Props {
  register: UseFormRegister<FormValues>
  errors: FieldErrors<FormValues>
  watchCountry: string
  setValue: UseFormSetValue<FormValues>
}

function getComponent(place: google.maps.places.PlaceResult, type: string, variant: 'long' | 'short' = 'long') {
  const comp = place.address_components?.find((c) => c.types.includes(type))
  return variant === 'short' ? comp?.short_name ?? '' : comp?.long_name ?? ''
}

export default function PersonalInfoSection({ register, errors, watchCountry, setValue }: Props) {
  const street1Ref = useRef<HTMLInputElement | null>(null)
  const autocompleteRef = useRef<google.maps.places.Autocomplete | null>(null)

  const { ref: formRef, ...street1Registration } = register('street1')

  const mergedRef = useCallback(
    (el: HTMLInputElement | null) => {
      formRef(el)
      street1Ref.current = el
    },
    [formRef],
  )

  useEffect(() => {
    if (autocompleteRef.current || !street1Ref.current) return

    const waitForGoogle = setInterval(() => {
      if (typeof google === 'undefined' || !google.maps?.places) return

      clearInterval(waitForGoogle)

      const ac = new google.maps.places.Autocomplete(street1Ref.current!, {
        types: ['address'],
        fields: ['address_components'],
      })

      ac.addListener('place_changed', () => {
        const place = ac.getPlace()
        if (!place.address_components) return

        const streetNumber = getComponent(place, 'street_number')
        const route = getComponent(place, 'route')
        const subpremise = getComponent(place, 'subpremise')
        const city =
          getComponent(place, 'locality') ||
          getComponent(place, 'sublocality_level_1') ||
          getComponent(place, 'postal_town')
        const state = getComponent(place, 'administrative_area_level_1', 'short')
        const postalCode = getComponent(place, 'postal_code')
        const country = getComponent(place, 'country')

        setValue('street1', [streetNumber, route].filter(Boolean).join(' '), { shouldValidate: true })
        if (subpremise) setValue('street2', subpremise, { shouldValidate: true })
        setValue('city', city, { shouldValidate: true })
        setValue('state', state, { shouldValidate: true })
        setValue('postalCode', postalCode, { shouldValidate: true })
        setValue('country', country, { shouldValidate: true })
      })

      autocompleteRef.current = ac
    }, 200)

    return () => clearInterval(waitForGoogle)
  }, [setValue])

  return (
    <>
      {/* Row 1: First Name, Last Name, Phone */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <div>
          <label>First Name <span className="required-star">*</span></label>
          <input type="text" {...register('firstName')} placeholder="" />
          {errors.firstName && <span className="field-error">{errors.firstName.message}</span>}
        </div>
        <div>
          <label>Last Name <span className="required-star">*</span></label>
          <input type="text" {...register('lastName')} placeholder="" />
          {errors.lastName && <span className="field-error">{errors.lastName.message}</span>}
        </div>
        <div>
          <label>Phone <span className="required-star">*</span></label>
          <input type="tel" {...register('phone')} placeholder="" />
          {errors.phone && <span className="field-error">{errors.phone.message}</span>}
        </div>
      </div>

      {/* Row 2: Email, Spouse First Name, Spouse Last Name */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <div>
          <label>Email <span className="required-star">*</span></label>
          <input type="email" {...register('email')} placeholder="" />
          {errors.email && <span className="field-error">{errors.email.message}</span>}
        </div>
        <div>
          <label>Spouse First Name</label>
          <input type="text" {...register('spouseFirstName')} placeholder="" />
        </div>
        <div>
          <label>Spouse Last Name</label>
          <input type="text" {...register('spouseLastName')} placeholder="" />
        </div>
      </div>

      {/* Row 3: Street 1, Street 2, Country */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <div>
          <label>Street 1 <span className="required-star">*</span></label>
          <input type="text" {...street1Registration} ref={mergedRef} placeholder="" />
          {errors.street1 && <span className="field-error">{errors.street1.message}</span>}
        </div>
        <div>
          <label>Street 2</label>
          <input type="text" {...register('street2')} placeholder="" />
        </div>
        <div>
          <label>Country <span className="required-star">*</span></label>
          <select {...register('country')}>
            <option value="">Select Country</option>
            {COUNTRIES.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
          {errors.country && <span className="field-error">{errors.country.message}</span>}
        </div>
      </div>

      {/* Row 4: State, City, Postal Code */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
        <div>
          <label>State <span className="required-star">*</span></label>
          {watchCountry === 'United States' ? (
            <select {...register('state')}>
              <option value="">Select State</option>
              {US_STATES.map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
          ) : (
            <input type="text" {...register('state')} placeholder="" />
          )}
          {errors.state && <span className="field-error">{errors.state.message}</span>}
        </div>
        <div>
          <label>City <span className="required-star">*</span></label>
          <input type="text" {...register('city')} placeholder="" />
          {errors.city && <span className="field-error">{errors.city.message}</span>}
        </div>
        <div>
          <label>Postal Code <span className="required-star">*</span></label>
          <input type="text" {...register('postalCode')} placeholder="" />
          {errors.postalCode && <span className="field-error">{errors.postalCode.message}</span>}
        </div>
      </div>
    </>
  )
}
