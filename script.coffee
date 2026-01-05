values_default =
    min: 550
    total: 1000

chalk = (v, class_name)-> "<span class='#{class_name}'>#{v}</span>"

hash_get = (param)->
    result =  window.location.hash.match(
        new RegExp("(\\?|&|#)" + param + "(\\[\\])?=([^&]*)")
    )
    if result
        return parseFloat(decodeURIComponent(result[3]))
    return false

hash_set = (ob)->
    window.location.hash = Object.keys(ob).reduce( (acc, field)->
        for def of values_default
            if ( field is def and parseFloat(ob[field]) is values_default[field] )
                return acc
        acc.concat ["#{field}=#{ob[field]}"]
    , [] ).join '&'


fn = ({total, bruto, neto, min})->
  round = (v)-> Math.round(v * 100) * 0.01
  r = (v, color = 1)->
    chalk v.toFixed(2), if color is 2 then 'legit' else if color is 3 then 'high1' else 'warn'
  tax_risk = 0.36
  calculate = ({total, bruto, neto})->
    if total
      bruto = (total - tax_risk) / 1.2359
    tax_sia = bruto * 0.2359
    tax_vsaoi = bruto * 0.1050
    # iin_params = [[min + tax_vsaoi, 0.2], [20004/12, 0.23], [78100/12, 0.31]]
    iin_params = [[min + tax_vsaoi, 0.255], [105300/12, 0.33]]
    tax_iin = iin_params.map (threshold, i, arr)->
      if bruto > threshold[0]
        return (bruto - threshold[0] ) * (threshold[1] - (if i > 0 then arr[i-1][1] else 0) )
      if i is 0
        return 0
      return null
    .filter (v)-> v isnt null
    tax_iin_total = tax_iin.reduce( ((a, b)-> a + b), 0)
    neto = round(bruto - tax_vsaoi - tax_iin_total)
    {neto, bruto, total, tax_sia, tax_vsaoi, iin_params, tax_iin, tax_iin_total}

  if neto
    do =>
      total_cal = neto * 1.7
      for i in [0..5000]
        total_cal_prev = total_cal
        neto_new = calculate({total: total_cal}).neto
        total_cal += (neto - neto_new)
        if total_cal_prev is total_cal
          total = total_cal
          break
  {neto, bruto, total, tax_sia, tax_vsaoi, iin_params, tax_iin, tax_iin_total} = calculate({total, bruto})

  {
    neto, min, bruto, total: bruto + tax_sia + tax_risk
    str: """
        total: #{r(bruto + tax_sia + tax_risk, 3)} = #{r(bruto)} (bruto) + #{r(tax_sia)} (vsaoi) + #{tax_risk} (riska nodeva)
        bruto: #{r(bruto, 2)}
        neto: #{r(neto, 3)}
        IIN: #{r( tax_iin_total )} = #{tax_iin.map( (amount, i)->
        """#{r(amount)} (no #{ Math.round(iin_params[i][0] * 1000)/1000 }#{if i is 0 then " (neapliekamais minimums (#{min}) + vsaoi (#{ Math.round(tax_vsaoi * 1000)/1000 }))" else ''} * #{iin_params[i][1]})"""
        ).join " + "}
        VASAOI: #{r(tax_sia + tax_vsaoi)} = #{r(tax_sia)} (darba devēja daļa) + #{r(tax_vsaoi)} (darba ņēmēja daļa)
        taxes: #{r(tax_sia + tax_vsaoi + tax_risk + tax_iin_total, 3)}
    """
  }


by_id = (field)-> document.getElementById(field)
by_id_value = (field)-> parseFloat(by_id(field).value or 0)
by_id_set = (field, value)-> by_id(field).value = value.toFixed(2)
result_show = (v)->
    by_id('result').innerHTML = v
fields = ['total', 'bruto', 'neto']
fields_all = fields.concat( ['min'] )
calculate = (field_change, update = true, escaped = [])->
    if fields.filter( (field)-> by_id_value(field) > 0 ).length is 0
        return result chalk 'Ievadiet vismaz vienu no algas cipariem!', 'error'
    if by_id_value(field_change) is 0
        if escaped.length <= 2
            field_change_new = fields.filter( (f)-> ! ( f is field_change or f in escaped ) )[0]
            return calculate(field_change_new, update, escaped.concat([field_change]))
        return result chalk 'Kaut kas nav labi.', 'error'
    result = fn ['min', field_change].reduce (acc, field)->
        Object.assign acc, {[field]: by_id_value(field)}
    , {}
    fields
    .filter (field2)-> field2 isnt field_change
    .forEach (field2)-> by_id(field2).value = result[field2].toFixed(2)
    if update
        hash_set {min: result['min'].toFixed(2), [field_change]: result[field_change].toFixed(2)}
    return result_show result.str.split("\n").join("<br />")

last_changed = null
onchange = (field)->
  if field isnt 'min' and by_id_value(field) <= 0
      return
  if field isnt 'min' and by_id_value(field) > 0
      last_changed = field
  calculate(if field is 'min' then last_changed or 'total' else field)
fields_all.forEach (field)->
  by_id(field).onkeyup = -> onchange(field)
  by_id(field).onchange = -> onchange(field)


by_id_set('min', if hash_get('min') is false then values_default['min'] else hash_get('min') )
for field in fields
    if hash_get(field)
        by_id_set(field, hash_get(field))
        calculate(field)
        return 
by_id_set('total', values_default['total'])
calculate('total')
