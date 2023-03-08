{
  PORT          = 3000
  NODE_ENV      = 'development'
} = process.env

axios   = require 'axios'
Koa     = require 'koa'
router  = do require 'koa-router'

#
# Routes
#
router.get '/', root = (ctx)->
  ctx.body = """
  Usage:

    GET   /
      this message

    GET   /metrics
      covid data in prometheus format
      Snooped from the ArcGIS dashboard at https://experience.arcgis.com/experience/a6f23959a8b14bfa989e3cda29297ded
  """

router.get '/metrics', (ctx)->
  [
    new_cases,
    # active_cases,
    total_cases,
    in_hospital,
    in_icu,
    total_deaths
  ] = await Promise.all [
    axios.get url 'NewCases'
    # axios.get url 'ActiveCases'
    axios.get url 'Cases'
    axios.get url 'CurrentlyHosp'
    axios.get url 'CurrentlyICU'
    axios.get url 'Deaths'
  ]

  blocks = [
    gauge   'new_cases',      dig(new_cases),      'New cases today'
    # gauge   'active_cases',   dig(active_cases),   'Active cases'
    gauge   'in_hospital',    dig(in_hospital),    'Number of hospitalized cases'
    gauge   'in_icu',         dig(in_icu),         'Number of cases in ICU'
    counter 'total_cases',    dig(total_cases),    'Total cases to date'
    counter 'total_deaths',   dig(total_deaths),   'Total deaths to date'
  ]

  ctx.body = blocks.join '\n\n'

#
# helpers
#
attrify = (attrs={})->
  ret = []
  for key, val of attrs when val?
    ret.push "#{key}=\"#{val}\"" if val?
  ret.join()

attrs =
  health_authority: 'Island'
  province: 'BC'

attr = (type, name, value, description)->
  """
  # HELP #{name} #{description}
  # TYPE #{name} #{type}
  #{name}{#{attrify attrs}} #{value}
  """
gauge = attr.bind null, 'gauge'
counter = attr.bind null, 'counter'

url = (name)-> "https://services1.arcgis.com/xeMpV7tU1t4KD3Ei/arcgis/rest/services/COVID19_Cases_by_BC_Health_Authority/FeatureServer/0/query?f=json&cacheHint=true&orderByFields=&outFields=*&outStatistics=[{%22onStatisticField%22:%22#{name}%22,%22outStatisticFieldName%22:%22value%22,%22statisticType%22:%22sum%22}]&resultType=standard&returnGeometry=false&spatialRel=esriSpatialRelIntersects&where=FID=4"
dig = ({status, data})-> data?.features?[0]?.attributes?.value or 0


#
# Server init
#
app = new Koa
app.use router.routes()
console.log "app listening on port #{PORT}"
app.listen PORT
