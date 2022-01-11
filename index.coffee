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
  dig = ({status, data})-> data.features[0].attributes.value

  [
    new_cases,
    active_cases,
    total_cases,
    in_hospital,
    in_icu,
    total_deaths
  ] = await Promise.all [
    dig await axios.get url 'NewCases'
    dig await axios.get url 'ActiveCases'
    dig await axios.get url 'Cases'
    dig await axios.get url 'CurrentlyHosp'
    dig await axios.get url 'CurrentlyICU'
    dig await axios.get url 'Deaths'
  ]

  blocks = [
    gauge   'new_cases',      new_cases,      'New cases today'
    gauge   'active_cases',   active_cases,   'Active cases'
    gauge   'in_hospital',    in_hospital,    'Number of hospitalized cases'
    gauge   'in_icu',         in_icu,         'Number of cases in ICU'
    counter 'total_cases',    total_cases,    'Total cases to date'
    counter 'total_deaths',   total_deaths,   'Total deaths to date'
  ]

  ctx.body = blocks.join '\n\n'

#
# Server init
#
app = new Koa
app.use router.routes()
app.listen PORT
