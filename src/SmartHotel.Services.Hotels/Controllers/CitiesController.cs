using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SmartHotel.Services.Hotels.Domain.Hotel;
using SmartHotel.Services.Hotels.Queries;

namespace SmartHotel.Services.Hotels.Controllers
{
    [Route("[controller]")]
    public class CitiesController : Controller
    {
        private readonly CitiesQuery _citiesQueries;

        public CitiesController(CitiesQuery citiesQueries)
        {
            _citiesQueries = citiesQueries;
        }

        [HttpGet]
        public async Task<ActionResult> Get(string name = "")
        {
            var cities = string.IsNullOrEmpty(name) ? 
                await _citiesQueries.GetDefaultCities() :
                await _citiesQueries.Get(name);
            return Ok(cities);
        }
    }
}
