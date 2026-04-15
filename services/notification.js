const axios = require('axios');

const ONESIGNAL_APP_ID = '761ea292-91d7-4566-8fa5-a7313205f0bf';
const ONESIGNAL_API_KEY = '7gnurhyt4uuyvwtk6j6mm2htj';

async function sendNotificationToPatient(playerId, ticketNumber, patientName) {
  if (!playerId) {
    console.log('Pas de playerId pour ce patient');
    return false;
  }

  const message = {
    app_id: ONESIGNAL_APP_ID,
    include_player_ids: [playerId],
    headings: { en: "Votre tour est arrive" },
    contents: { 
      en: "Ticket " + ticketNumber + " - " + patientName + ", veuillez vous presenter au cabinet." 
    },
    data: {
      ticketId: ticketNumber,
      type: "called"
    }
  };

  try {
    const response = await axios.post(
      'https://onesignal.com/api/v1/notifications',
      message,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ' + ONESIGNAL_API_KEY
        }
      }
    );
    console.log('Notification envoyee a ' + patientName);
    return true;
  } catch (error) {
    console.error('Erreur envoi notification:', error.response?.data || error.message);
    return false;
  }
}

module.exports = { sendNotificationToPatient };